import Fastify, { type FastifyInstance } from 'fastify';
import type { Signer } from './pass/signer';
import { passRoutes } from './routes/pass';

export type AppDeps = {
  signer: Signer;
  logger?: boolean;
};

export const buildApp = ({ signer, logger = false }: AppDeps): FastifyInstance => {
  const app = Fastify({ logger });
  app.get('/health', async () => ({ ok: true }));
  app.register(passRoutes(signer));
  return app;
};
