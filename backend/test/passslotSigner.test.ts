import { beforeEach, describe, expect, it, vi } from 'vitest';
import {
  createPassslotSigner,
  mapRequestToPlaceholders,
} from '../src/pass/passslotSigner';
import type { PassRequest } from '../src/pass/signer';

const validRequest: PassRequest = {
  type: 'storeCard',
  label: 'Coffee',
  description: 'Loyalty card',
  colors: {
    background: '#0A2540',
    foreground: '#FFFFFF',
    label: '#7AC0FF',
  },
  barcode: { format: 'qr', message: 'abc-123', altText: 'abc' },
};

const expectedAuthHeader = 'Basic ' + Buffer.from('test-key:').toString('base64');

const makeCreateResponse = (overrides: Record<string, unknown> = {}) =>
  new Response(
    JSON.stringify({
      passTypeIdentifier: 'pass.com.passslot.demo',
      serialNumber: 'serial-1',
      url: 'https://api.passslot.com/v1/passes/pass.com.passslot.demo/serial-1',
      ...overrides,
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );

const makeDownloadResponse = (body = 'PASSSLOT_BYTES') =>
  new Response(body, {
    status: 200,
    headers: { 'Content-Type': 'application/vnd.apple.pkpass' },
  });

describe('mapRequestToPlaceholders', () => {
  it('flattens the request into PassSlot placeholders', () => {
    expect(mapRequestToPlaceholders(validRequest)).toEqual({
      label: 'Coffee',
      description: 'Loyalty card',
      passType: 'storeCard',
      barcodeMessage: 'abc-123',
      barcodeAltText: 'abc',
    });
  });

  it('coerces a missing altText to an empty string', () => {
    const result = mapRequestToPlaceholders({
      ...validRequest,
      barcode: { ...validRequest.barcode, altText: undefined },
    });
    expect(result.barcodeAltText).toBe('');
  });
});

describe('createPassslotSigner', () => {
  let fetchMock: ReturnType<typeof vi.fn>;

  const buildSigner = () =>
    createPassslotSigner(
      { appKey: 'test-key', templateId: 'tpl-42' },
      fetchMock as unknown as typeof fetch,
    );

  beforeEach(() => {
    fetchMock = vi.fn();
  });

  it('creates the pass then downloads it and returns the bytes', async () => {
    fetchMock
      .mockResolvedValueOnce(makeCreateResponse())
      .mockResolvedValueOnce(makeDownloadResponse('SIGNED'));

    const data = await buildSigner().sign(validRequest);
    expect(data.toString()).toBe('SIGNED');

    expect(fetchMock).toHaveBeenCalledTimes(2);

    const [createUrl, createInit] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(createUrl).toBe('https://api.passslot.com/v1/templates/tpl-42/pass');
    expect(createInit.method).toBe('POST');
    expect((createInit.headers as Record<string, string>).Authorization).toBe(
      expectedAuthHeader,
    );
    expect((createInit.headers as Record<string, string>)['Content-Type']).toBe(
      'application/json',
    );
    expect(JSON.parse(createInit.body as string)).toEqual({
      label: 'Coffee',
      description: 'Loyalty card',
      passType: 'storeCard',
      barcodeMessage: 'abc-123',
      barcodeAltText: 'abc',
    });

    const [downloadUrl, downloadInit] = fetchMock.mock.calls[1] as [string, RequestInit];
    expect(downloadUrl).toBe(
      'https://api.passslot.com/v1/passes/pass.com.passslot.demo/serial-1',
    );
    expect((downloadInit.headers as Record<string, string>).Authorization).toBe(
      expectedAuthHeader,
    );
  });

  it('ignores the url field in the create response and uses the API download path', async () => {
    fetchMock
      .mockResolvedValueOnce(
        makeCreateResponse({
          url: 'https://d.pslot.io/p/some-landing-page?t=token',
        }),
      )
      .mockResolvedValueOnce(makeDownloadResponse());

    await buildSigner().sign(validRequest);

    const [downloadUrl] = fetchMock.mock.calls[1] as [string];
    expect(downloadUrl).toBe(
      'https://api.passslot.com/v1/passes/pass.com.passslot.demo/serial-1',
    );
    expect(downloadUrl).not.toContain('pslot.io');
  });

  it('throws when the create-pass request fails', async () => {
    fetchMock.mockResolvedValueOnce(
      new Response('rate limited', { status: 429 }),
    );

    await expect(buildSigner().sign(validRequest)).rejects.toThrow(
      /create-pass failed \(429\): rate limited/,
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('throws when the download request fails', async () => {
    fetchMock
      .mockResolvedValueOnce(makeCreateResponse())
      .mockResolvedValueOnce(new Response('not found', { status: 404 }));

    await expect(buildSigner().sign(validRequest)).rejects.toThrow(
      /download-pass failed \(404\): not found/,
    );
  });

  it('throws when the create response is missing identifiers', async () => {
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({}), { status: 200 }),
    );

    await expect(buildSigner().sign(validRequest)).rejects.toThrow(
      /missing passTypeIdentifier or serialNumber/,
    );
  });

  it('honours a custom baseUrl', async () => {
    fetchMock
      .mockResolvedValueOnce(makeCreateResponse({ url: undefined }))
      .mockResolvedValueOnce(makeDownloadResponse());

    const signer = createPassslotSigner(
      {
        appKey: 'test-key',
        templateId: 'tpl-42',
        baseUrl: 'https://example.test/api/v1/',
      },
      fetchMock as unknown as typeof fetch,
    );

    await signer.sign(validRequest);

    const [createUrl] = fetchMock.mock.calls[0] as [string];
    expect(createUrl).toBe('https://example.test/api/v1/templates/tpl-42/pass');
    const [downloadUrl] = fetchMock.mock.calls[1] as [string];
    expect(downloadUrl).toBe(
      'https://example.test/api/v1/passes/pass.com.passslot.demo/serial-1',
    );
  });
});
