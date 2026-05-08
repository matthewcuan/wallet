import type { FastifyPluginAsync } from 'fastify';
import type { PassRequest, Signer } from '../pass/signer';

const passBodySchema = {
  type: 'object',
  required: ['type', 'label', 'description', 'colors', 'barcode'],
  additionalProperties: false,
  properties: {
    type: {
      enum: ['storeCard', 'generic', 'coupon', 'eventTicket', 'boardingPass'],
    },
    label: { type: 'string', minLength: 1, maxLength: 64 },
    description: { type: 'string', minLength: 1, maxLength: 256 },
    colors: {
      type: 'object',
      required: ['background', 'foreground', 'label'],
      additionalProperties: false,
      properties: {
        background: { type: 'string', pattern: '^#[0-9A-Fa-f]{6}$' },
        foreground: { type: 'string', pattern: '^#[0-9A-Fa-f]{6}$' },
        label: { type: 'string', pattern: '^#[0-9A-Fa-f]{6}$' },
      },
    },
    barcode: {
      type: 'object',
      required: ['format', 'message'],
      additionalProperties: false,
      properties: {
        format: { enum: ['qr', 'pdf417', 'aztec', 'code128'] },
        message: { type: 'string', minLength: 1, maxLength: 4096 },
        altText: { type: 'string', maxLength: 128 },
      },
    },
  },
} as const;

export const passRoutes =
  (signer: Signer): FastifyPluginAsync =>
  async (app) => {
    app.post<{ Body: PassRequest }>(
      '/pass',
      { schema: { body: passBodySchema } },
      async (request, reply) => {
        const buffer = await signer.sign(request.body);
        return reply
          .header('Content-Type', 'application/vnd.apple.pkpass')
          .send(buffer);
      },
    );
  };
