import { randomUUID } from 'node:crypto';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { PKPass } from 'passkit-generator';
import type { Config } from '../config';
import type { BarcodeFormat, Signer } from './signer';

export type Certificates = {
  wwdr: Buffer;
  signerCert: Buffer;
  signerKey: Buffer;
  signerKeyPassphrase?: string;
};

export type RealSignerConfig = {
  certificates: Certificates;
  passTypeIdentifier: string;
  teamIdentifier: string;
  organizationName: string;
  templatesPath: string;
};

// Builds a Signer that produces real, signed .pkpass buffers via passkit-generator.
// `templatesPath` must contain one subdirectory per PassType (storeCard, generic, etc.)
// holding the required Apple Wallet assets — pass.json, icon.png/@2x/@3x, logo.png/@2x/@3x.
// Final end-to-end validation requires a real Pass Type ID certificate and a device.
export const createRealSigner = (config: RealSignerConfig): Signer => ({
  async sign(request) {
    const modelDir = path.join(config.templatesPath, request.type);

    const pass = await PKPass.from(
      {
        model: modelDir,
        certificates: config.certificates,
      },
      {
        serialNumber: randomUUID(),
        description: request.description,
        organizationName: config.organizationName,
        passTypeIdentifier: config.passTypeIdentifier,
        teamIdentifier: config.teamIdentifier,
        logoText: request.label,
        backgroundColor: hexToRgb(request.colors.background),
        foregroundColor: hexToRgb(request.colors.foreground),
        labelColor: hexToRgb(request.colors.label),
      },
    );

    pass.setBarcodes({
      format: barcodeFormatToApple(request.barcode.format),
      message: request.barcode.message,
      messageEncoding: 'iso-8859-1',
      altText: request.barcode.altText,
    });

    return pass.getAsBuffer();
  },
});

// Loads cert files from disk and constructs a real signer from environment config.
// Throws if any cert is unreadable so the failure surfaces at boot, not on the
// first request.
export const loadRealSigner = async (config: Config): Promise<Signer> => {
  const [wwdr, signerCert, signerKey] = await Promise.all([
    fs.readFile(config.wwdrCertPath),
    fs.readFile(config.signerCertPath),
    fs.readFile(config.signerKeyPath),
  ]);

  return createRealSigner({
    certificates: {
      wwdr,
      signerCert,
      signerKey,
      signerKeyPassphrase: config.signerKeyPassphrase || undefined,
    },
    passTypeIdentifier: config.passTypeIdentifier,
    teamIdentifier: config.teamIdentifier,
    organizationName: config.organizationName,
    templatesPath: config.templatesPath,
  });
};

export const hexToRgb = (hex: string): string => {
  const cleaned = hex.startsWith('#') ? hex.slice(1) : hex;
  if (!/^[0-9a-fA-F]{6}$/.test(cleaned)) {
    throw new Error(`Invalid hex color: ${hex}`);
  }
  const value = parseInt(cleaned, 16);
  const r = (value >> 16) & 0xff;
  const g = (value >> 8) & 0xff;
  const b = value & 0xff;
  return `rgb(${r}, ${g}, ${b})`;
};

export const barcodeFormatToApple = (
  format: BarcodeFormat,
):
  | 'PKBarcodeFormatQR'
  | 'PKBarcodeFormatPDF417'
  | 'PKBarcodeFormatAztec'
  | 'PKBarcodeFormatCode128' => {
  switch (format) {
    case 'qr':
      return 'PKBarcodeFormatQR';
    case 'pdf417':
      return 'PKBarcodeFormatPDF417';
    case 'aztec':
      return 'PKBarcodeFormatAztec';
    case 'code128':
      return 'PKBarcodeFormatCode128';
  }
};
