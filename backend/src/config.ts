import 'dotenv/config';

export type Config = {
  host: string;
  port: number;
  mockSigner: boolean;
  passTypeIdentifier: string;
  teamIdentifier: string;
  organizationName: string;
  passCertPath: string;
  passCertPassword: string;
  wwdrCertPath: string;
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
    passCertPath: process.env.PASS_CERT_PATH ?? '',
    passCertPassword: process.env.PASS_CERT_PASSWORD ?? '',
    wwdrCertPath: process.env.WWDR_CERT_PATH ?? '',
  };

  if (!mockSigner) {
    const required: Array<keyof Config> = [
      'passTypeIdentifier',
      'teamIdentifier',
      'passCertPath',
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
