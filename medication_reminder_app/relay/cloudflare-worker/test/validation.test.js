import test from 'node:test';
import assert from 'node:assert/strict';

import { validatePayload } from '../src/index.js';

const valid = {
  replyEmail: 'person@example.com',
  subject: 'Question',
  message: 'This is a sufficiently long contact message.',
  languageCode: 'en',
  source: 'medication-reminder-app',
  clientId: 'a'.repeat(32),
  messageId: 'b'.repeat(32),
  website: '',
};

test('accepts the bounded app payload', () => {
  assert.equal(validatePayload(valid).ok, true);
});

test('rejects header injection, bot bait, and unknown clients', () => {
  assert.equal(validatePayload({ ...valid, subject: 'Hi\r\nBcc: x@y.nl' }).ok, false);
  assert.equal(validatePayload({ ...valid, website: 'https://spam.test' }).ok, false);
  assert.equal(validatePayload({ ...valid, clientId: 'guessable' }).ok, false);
});

test('rejects oversized content', () => {
  assert.equal(validatePayload({ ...valid, message: 'x'.repeat(4001) }).ok, false);
});
