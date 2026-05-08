import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';
import { createMockSigner } from '../src/pass/mockSigner';
import type { PassRequest } from '../src/pass/signer';

const validBody: PassRequest = {
  type: 'storeCard',
  label: 'Coffee Shop',
  description: 'Loyalty card',
  colors: {
    background: '#0A2540',
    foreground: '#FFFFFF',
    label: '#7AC0FF',
  },
  barcode: {
    format: 'qr',
    message: 'CUSTOMER-12345',
    altText: '12345',
  },
};

const buildTestApp = () => buildApp({ signer: createMockSigner() });

describe('POST /pass', () => {
  it('returns a pkpass-typed body for a valid request', async () => {
    const app = buildTestApp();
    const response = await app.inject({
      method: 'POST',
      url: '/pass',
      payload: validBody,
    });

    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toContain(
      'application/vnd.apple.pkpass',
    );

    const payload = JSON.parse(response.body);
    expect(payload.mock).toBe(true);
    expect(payload.request.label).toBe('Coffee Shop');
    expect(payload.request.barcode.message).toBe('CUSTOMER-12345');
  });

  it('rejects a body missing required fields', async () => {
    const app = buildTestApp();
    const response = await app.inject({
      method: 'POST',
      url: '/pass',
      payload: { type: 'storeCard' },
    });

    expect(response.statusCode).toBe(400);
  });

  it('rejects an invalid color hex', async () => {
    const app = buildTestApp();
    const response = await app.inject({
      method: 'POST',
      url: '/pass',
      payload: {
        ...validBody,
        colors: { ...validBody.colors, background: 'not-a-color' },
      },
    });

    expect(response.statusCode).toBe(400);
  });

  it('rejects an unknown pass type', async () => {
    const app = buildTestApp();
    const response = await app.inject({
      method: 'POST',
      url: '/pass',
      payload: { ...validBody, type: 'invalid' },
    });

    expect(response.statusCode).toBe(400);
  });

  it('rejects an unknown barcode format', async () => {
    const app = buildTestApp();
    const response = await app.inject({
      method: 'POST',
      url: '/pass',
      payload: {
        ...validBody,
        barcode: { ...validBody.barcode, format: 'morse' },
      },
    });

    expect(response.statusCode).toBe(400);
  });
});

describe('GET /health', () => {
  it('returns ok', async () => {
    const app = buildTestApp();
    const response = await app.inject({ method: 'GET', url: '/health' });
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ ok: true });
  });
});
