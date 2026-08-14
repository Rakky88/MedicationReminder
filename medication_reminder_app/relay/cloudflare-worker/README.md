# Secure contact relay

This Cloudflare Worker accepts the in-app contact form at `POST /contact` and
forwards it through Resend. The destination address and API key exist only as
encrypted Worker secrets. The endpoint validates strict size limits, rejects
header injection and honeypot submissions, rate-limits both each anonymous app
installation and its Cloudflare network address, prevents duplicate mail through
a request id, and never returns submitted content or upstream error details.

## Cost and accounts

- The relay itself fits comfortably in Cloudflare Workers Free for ordinary app
  use. The automatically assigned HTTPS `workers.dev` address needs no domain.
- Resend Free currently covers 3,000 messages per month and 100 per day.
- `onboarding@resend.dev` may only be used to send test messages to the address
  belonging to the Resend account. For a published app, verify a domain you own
  and use an address on that domain. The provider plans can therefore remain
  free, but buying/renewing that domain is a separate possible cost.
- Account creation, accepting provider terms, email/domain verification and
  secret entry must be performed by the account owner. Never paste API keys in
  source control, the Flutter build, screenshots, or chat.

## One-time deployment

1. Create the Cloudflare and Resend accounts. For a private test, use the Resend
   account address as `CONTACT_TO` and `Medication Reminder
   <onboarding@resend.dev>` as `CONTACT_FROM`. Before publication, verify a
   sender domain in Resend and replace `CONTACT_FROM` with an address on it.
2. Create a sending-only Resend API key.
3. Run `npm install` in this directory and authenticate with `npx wrangler login`.
4. Set all three secrets without placing their values in source control:
   `npx wrangler secret put RESEND_API_KEY`,
   `npx wrangler secret put CONTACT_TO`, and
   `npx wrangler secret put CONTACT_FROM`.
5. Run `npm test`, then `npm run deploy`.
6. Check `https://<worker-url>/health` and build Flutter with:
   `--dart-define=CONTACT_FORM_ENDPOINT=https://<worker-url>/contact`.

Enter the private destination only when Wrangler prompts for `CONTACT_TO`.
It is intentionally absent from the app binary and Worker source.
