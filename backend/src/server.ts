import { buildApp } from './app';
import { loadConfig } from './config';
import { createMockSigner } from './pass/mockSigner';
import { loadRealSigner } from './pass/realSigner';
import type { Signer } from './pass/signer';

const main = async (): Promise<void> => {
  const config = loadConfig();
  const signer: Signer = config.mockSigner
    ? createMockSigner()
    : await loadRealSigner(config);

  const app = buildApp({ signer, logger: true });
  await app.listen({ host: config.host, port: config.port });
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
