import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('passkit-generator', () => ({
  PKPass: { from: vi.fn() },
}));

import { PKPass } from 'passkit-generator';
import {
  barcodeFormatToApple,
  createRealSigner,
  hexToRgb,
  type Certificates,
} from '../src/pass/realSigner';
import type { PassRequest } from '../src/pass/signer';

const fromMock = vi.mocked(PKPass.from);

const fakeCerts: Certificates = {
  wwdr: Buffer.from('WWDR'),
  signerCert: Buffer.from('SIGNER_CERT'),
  signerKey: Buffer.from('SIGNER_KEY'),
  signerKeyPassphrase: 'pw',
};

const buildSigner = () =>
  createRealSigner({
    certificates: fakeCerts,
    passTypeIdentifier: 'pass.com.example.test',
    teamIdentifier: 'TEAM12345',
    organizationName: 'Wallet',
    templatesPath: '/tmp/templates',
  });

const buildRequest = (overrides: Partial<PassRequest> = {}): PassRequest => ({
  type: 'storeCard',
  label: 'Coffee',
  description: 'Loyalty card',
  colors: {
    background: '#0A2540',
    foreground: '#FFFFFF',
    label: '#7AC0FF',
  },
  barcode: { format: 'qr', message: 'abc-123', altText: 'abc' },
  ...overrides,
});

describe('hexToRgb', () => {
  it('converts hex with # prefix', () => {
    expect(hexToRgb('#FFFFFF')).toBe('rgb(255, 255, 255)');
  });

  it('converts hex without # prefix', () => {
    expect(hexToRgb('000000')).toBe('rgb(0, 0, 0)');
  });

  it('handles mixed-case hex', () => {
    expect(hexToRgb('#0a2540')).toBe('rgb(10, 37, 64)');
  });

  it('throws on invalid hex', () => {
    expect(() => hexToRgb('not-a-color')).toThrow(/Invalid hex/);
    expect(() => hexToRgb('#FFF')).toThrow(/Invalid hex/);
    expect(() => hexToRgb('#GGGGGG')).toThrow(/Invalid hex/);
  });
});

describe('barcodeFormatToApple', () => {
  it.each([
    ['qr', 'PKBarcodeFormatQR'],
    ['pdf417', 'PKBarcodeFormatPDF417'],
    ['aztec', 'PKBarcodeFormatAztec'],
    ['code128', 'PKBarcodeFormatCode128'],
  ] as const)('maps %s to %s', (input, expected) => {
    expect(barcodeFormatToApple(input)).toBe(expected);
  });
});

describe('createRealSigner', () => {
  beforeEach(() => {
    fromMock.mockReset();
  });

  const stubPass = () => {
    const setBarcodes = vi.fn();
    const getAsBuffer = vi.fn(() => Buffer.from('SIGNED_PASS'));
    const pass = { setBarcodes, getAsBuffer } as unknown as PKPass;
    fromMock.mockResolvedValue(pass);
    return { pass, setBarcodes, getAsBuffer };
  };

  it('returns the buffer produced by passkit-generator', async () => {
    const { getAsBuffer } = stubPass();
    const signer = buildSigner();

    const result = await signer.sign(buildRequest());

    expect(result).toEqual(Buffer.from('SIGNED_PASS'));
    expect(getAsBuffer).toHaveBeenCalledOnce();
  });

  it('passes certs and the pass-type-specific template path', async () => {
    stubPass();
    const signer = buildSigner();

    await signer.sign(buildRequest({ type: 'eventTicket' }));

    const [source] = fromMock.mock.calls[0]!;
    expect(source).toMatchObject({
      model: '/tmp/templates/eventTicket',
      certificates: fakeCerts,
    });
  });

  it('translates colors to rgb() and copies identifiers from config', async () => {
    stubPass();
    const signer = buildSigner();

    await signer.sign(buildRequest());

    const [, props] = fromMock.mock.calls[0]!;
    expect(props).toMatchObject({
      description: 'Loyalty card',
      organizationName: 'Wallet',
      passTypeIdentifier: 'pass.com.example.test',
      teamIdentifier: 'TEAM12345',
      logoText: 'Coffee',
      backgroundColor: 'rgb(10, 37, 64)',
      foregroundColor: 'rgb(255, 255, 255)',
      labelColor: 'rgb(122, 192, 255)',
    });
    expect(typeof props?.serialNumber).toBe('string');
    expect(props?.serialNumber).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    );
  });

  it('forwards the barcode with the Apple format and the iso-8859-1 encoding', async () => {
    const { setBarcodes } = stubPass();
    const signer = buildSigner();

    await signer.sign(
      buildRequest({
        barcode: { format: 'pdf417', message: 'XYZ-9', altText: 'human' },
      }),
    );

    expect(setBarcodes).toHaveBeenCalledWith({
      format: 'PKBarcodeFormatPDF417',
      message: 'XYZ-9',
      messageEncoding: 'iso-8859-1',
      altText: 'human',
    });
  });

  it('omits altText cleanly when not provided', async () => {
    const { setBarcodes } = stubPass();
    const signer = buildSigner();

    await signer.sign(
      buildRequest({
        barcode: { format: 'qr', message: 'abc', altText: undefined },
      }),
    );

    const [arg] = setBarcodes.mock.calls[0]!;
    expect(arg.altText).toBeUndefined();
  });
});
