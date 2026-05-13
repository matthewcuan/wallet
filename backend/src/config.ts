import 'dotenv/config';

export const SIGNER_TYPES = ['mock', 'passslot', 'passkit'] as const;
export type SignerType = (typeof SIGNER_TYPES)[number];

export type Config = {
  host: string;
  port: number;
  signer: SignerType;
  // passkit-generator (real Apple-issued certs)
  passTypeIdentifier: string;
  teamIdentifier: string;
  organizationName: string;
  signerCertPath: string;
  signerKeyPath: string;
  signerKeyPassphrase: string;
  wwdrCertPath: string;
  templatesPath: string;
  // passslot.com hosted signer
  passslotAppKey: string;
  passslotTemplateId: string;
  passslotBaseUrl: string;
};

const parseSignerType = (raw: string | undefined): SignerType => {
  const value = (raw ?? 'mock').toLowerCase();
  if ((SIGNER_TYPES as readonly string[]).includes(value)) {
    return value as SignerType;
  }
  throw new Error(
    `SIGNER must be one of ${SIGNER_TYPES.join(', ')}; got ${JSON.stringify(raw)}`,
  );
};

export const loadConfig = (): Config => {
  const config: Config = {
    host: process.env.HOST ?? '0.0.0.0',
    port: Number(process.env.PORT ?? 3000),
    signer: parseSignerType(process.env.SIGNER),
    passTypeIdentifier: process.env.PASS_TYPE_IDENTIFIER ?? '',
    teamIdentifier: process.env.TEAM_IDENTIFIER ?? '',
    organizationName: process.env.ORGANIZATION_NAME ?? 'Wallet',
    signerCertPath: process.env.SIGNER_CERT_PATH ?? '',
    signerKeyPath: process.env.SIGNER_KEY_PATH ?? '',
    signerKeyPassphrase: process.env.SIGNER_KEY_PASSPHRASE ?? '',
    wwdrCertPath: process.env.WWDR_CERT_PATH ?? '',
    templatesPath: process.env.TEMPLATES_PATH ?? './templates',
    passslotAppKey: process.env.PASSSLOT_APP_KEY ?? '',
    passslotTemplateId: process.env.PASSSLOT_TEMPLATE_ID ?? '',
    passslotBaseUrl: process.env.PASSSLOT_BASE_URL ?? 'https://api.passslot.com/v1',
  };

  validateForSigner(config);
  return config;
};

const validateForSigner = (config: Config): void => {
  const required: Partial<Record<SignerType, Array<keyof Config>>> = {
    passkit: [
      'passTypeIdentifier',
      'teamIdentifier',
      'signerCertPath',
      'signerKeyPath',
      'wwdrCertPath',
    ],
    passslot: ['passslotAppKey', 'passslotTemplateId'],
  };

  const fields = required[config.signer];
  if (!fields) return;

  for (const key of fields) {
    if (!config[key]) {
      throw new Error(
        `SIGNER=${config.signer} requires ${key} to be set (or set SIGNER=mock)`,
      );
    }
  }
};
