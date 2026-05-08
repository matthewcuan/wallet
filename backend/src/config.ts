import 'dotenv/config';

export type Config = {
  host: string;
  port: number;
  mockSigner: boolean;
  passTypeIdentifier: string;
  teamIdentifier: string;
  organizationName: string;
  signerCertPath: string;
  signerKeyPath: string;
  signerKeyPassphrase: string;
  wwdrCertPath: string;
  templatesPath: string;
};

export const loadConfig = (): Config => {
  const mockSigner = process.env.MOCK_SIGNER !== 'false';
  const config: Config = {
    host: process.env.HOST ?? '0.0.0.0',
    port: Number(process.env.PORT ?? 3000),
    mockSigner,
    passTypeIdentifier: process.env.PASS_TYPE_IDENTIFIER ?? '',
    teamIdentifier: process.env.TEAM_IDENTIFIER ?? '',
    organizationName: process.env.ORGANIZATION_NAME ?? 'Wallet',
    signerCertPath: process.env.SIGNER_CERT_PATH ?? '',
    signerKeyPath: process.env.SIGNER_KEY_PATH ?? '',
    signerKeyPassphrase: process.env.SIGNER_KEY_PASSPHRASE ?? '',
    wwdrCertPath: process.env.WWDR_CERT_PATH ?? '',
    templatesPath: process.env.TEMPLATES_PATH ?? './templates',
  };

  if (!mockSigner) {
    const required: Array<keyof Config> = [
      'passTypeIdentifier',
      'teamIdentifier',
      'signerCertPath',
      'signerKeyPath',
      'wwdrCertPath',
    ];
    for (const key of required) {
      if (!config[key]) {
        throw new Error(
          `Real signer requires ${key} to be set (or set MOCK_SIGNER=true)`,
        );
      }
    }
  }

  return config;
};
