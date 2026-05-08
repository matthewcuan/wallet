import { buildApp } from './app';
import { loadConfig } from './config';
import { createMockSigner } from './pass/mockSigner';

const main = async (): Promise<void> => {
  const config = loadConfig();

  if (!config.mockSigner) {
    throw new Error(
      'Real signer is not yet implemented. Set MOCK_SIGNER=true or wire up the passkit-generator integration.',
    );
  }

  const signer = createMockSigner();
  const app = buildApp({ signer, logger: true });

  await app.listen({ host: config.host, port: config.port });
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
