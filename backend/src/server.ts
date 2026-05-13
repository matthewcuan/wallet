import { buildApp } from './app';
import { loadConfig, type Config } from './config';
import { createMockSigner } from './pass/mockSigner';
import { createPassslotSigner } from './pass/passslotSigner';
import { loadRealSigner } from './pass/realSigner';
import type { Signer } from './pass/signer';

const buildSigner = async (config: Config): Promise<Signer> => {
  switch (config.signer) {
    case 'mock':
      return createMockSigner();
    case 'passslot':
      return createPassslotSigner({
        appKey: config.passslotAppKey,
        templateId: config.passslotTemplateId,
        baseUrl: config.passslotBaseUrl,
      });
    case 'passkit':
      return loadRealSigner(config);
  }
};

const main = async (): Promise<void> => {
  const config = loadConfig();
  const signer = await buildSigner(config);
  const app = buildApp({ signer, logger: true });
  await app.listen({ host: config.host, port: config.port });
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
