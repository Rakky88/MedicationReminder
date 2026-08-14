const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
  'Cache-Control': 'no-store',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
};

const emailPattern = /^[^\s@\r\n]+@[^\s@\r\n]+\.[^\s@\r\n]+$/;
const hexIdPattern = /^[a-f0-9]{32}$/;

function json(status, body) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function cleanString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

export function validatePayload(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    return { ok: false, error: 'invalid_request' };
  }

  const replyEmail = cleanString(value.replyEmail).toLowerCase();
  const subject = cleanString(value.subject);
  const message = cleanString(value.message);
  const languageCode = cleanString(value.languageCode);
  const source = cleanString(value.source);
  const clientId = cleanString(value.clientId);
  const messageId = cleanString(value.messageId);
  const website = cleanString(value.website);

  if (website !== '') return { ok: false, error: 'invalid_request' };
  if (
    replyEmail.length > 254 ||
    !emailPattern.test(replyEmail) ||
    subject.length < 1 ||
    subject.length > 120 ||
    /[\r\n]/.test(subject) ||
    message.length < 10 ||
    message.length > 4000 ||
    !['en', 'nl'].includes(languageCode) ||
    source !== 'medication-reminder-app' ||
    !hexIdPattern.test(clientId) ||
    !hexIdPattern.test(messageId)
  ) {
    return { ok: false, error: 'invalid_request' };
  }

  return {
    ok: true,
    payload: {
      replyEmail,
      subject,
      message,
      languageCode,
      clientId,
      messageId,
    },
  };
}

async function contact(request, env) {
  const contentType = request.headers.get('content-type') ?? '';
  const declaredLength = Number(request.headers.get('content-length') ?? '0');
  if (!contentType.toLowerCase().startsWith('application/json')) {
    return json(415, { ok: false, error: 'json_required' });
  }
  if (declaredLength > 6500) {
    return json(413, { ok: false, error: 'request_too_large' });
  }

  const raw = await request.text();
  if (raw.length > 6500) {
    return json(413, { ok: false, error: 'request_too_large' });
  }

  let decoded;
  try {
    decoded = JSON.parse(raw);
  } catch {
    return json(400, { ok: false, error: 'invalid_json' });
  }
  const validation = validatePayload(decoded);
  if (!validation.ok) return json(400, validation);

  const payload = validation.payload;
  const rate = await env.CONTACT_RATE_LIMITER.limit({
    key: `contact:${payload.clientId}`,
  });
  // A client id alone can be replaced by a modified app. The secondary edge
  // network limit makes that bypass substantially less useful while leaving
  // enough headroom for legitimate users behind a shared mobile connection.
  // CF-Connecting-IP is supplied by Cloudflare rather than trusted from JSON.
  const networkRate = await env.CONTACT_NETWORK_RATE_LIMITER.limit({
    key: `contact-network:${request.headers.get('CF-Connecting-IP') ?? 'unknown'}`,
  });
  if (!rate.success || !networkRate.success) {
    return json(429, { ok: false, error: 'rate_limited' });
  }

  const upstream = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
      'User-Agent': 'MedicationReminderContactRelay/1.0',
      'Idempotency-Key': `contact-${payload.messageId}`,
    },
    body: JSON.stringify({
      from: env.CONTACT_FROM,
      to: [env.CONTACT_TO],
      reply_to: payload.replyEmail,
      subject: `[Medication Reminder] ${payload.subject}`,
      text: [
        `Reply address: ${payload.replyEmail}`,
        `App language: ${payload.languageCode}`,
        '',
        payload.message,
      ].join('\n'),
    }),
  });

  if (!upstream.ok) {
    // Do not leak upstream details or submitted personal data to the client.
    return json(502, { ok: false, error: 'delivery_failed' });
  }
  return json(202, { ok: true });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return json(200, { ok: true });
    }
    if (request.method !== 'POST' || url.pathname !== '/contact') {
      return json(404, { ok: false, error: 'not_found' });
    }
    try {
      return await contact(request, env);
    } catch {
      return json(500, { ok: false, error: 'internal_error' });
    }
  },
};
