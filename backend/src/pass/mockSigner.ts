import type { Signer } from './signer';

// Returns a JSON buffer that echoes the request, tagged so callers can
// recognise it. Intentionally NOT a valid pkpass — replace with the
// passkit-generator-backed signer once a Pass Type ID certificate is wired up.
export const createMockSigner = (): Signer => ({
  async sign(request) {
    const payload = {
      mock: true,
      issuedAt: new Date().toISOString(),
      request,
    };
    return Buffer.from(JSON.stringify(payload, null, 2));
  },
});
