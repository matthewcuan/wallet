import type { PassRequest, Signer } from './signer';

export type PassslotSignerConfig = {
  appKey: string;
  templateId: string;
  baseUrl?: string;
};

const DEFAULT_BASE_URL = 'https://api.passslot.com/v1';

type CreatePassResponse = {
  passTypeIdentifier: string;
  serialNumber: string;
};

// PassSlot is a hosted pkpass-signing service. The user designs a template
// on passslot.com (with placeholders), gets an App Key, then this signer
// POSTs placeholder values and downloads the signed pkpass — no Apple
// Developer Program required. The template owns the pass type, layout,
// images and colors; this signer only supplies dynamic values.
//
// Convention for placeholders the template should define:
//   - label              (string)  the card's display label
//   - description        (string)  Wallet description
//   - passType           (string)  e.g. storeCard
//   - barcodeMessage     (string)  the scanned value, wired into the
//                                  template's barcode field
//   - barcodeAltText     (string)  optional human-readable below barcode
export const createPassslotSigner = (
  config: PassslotSignerConfig,
  fetchImpl: typeof fetch = fetch,
): Signer => {
  const baseUrl = (config.baseUrl ?? DEFAULT_BASE_URL).replace(/\/+$/, '');
  const authHeader = 'Basic ' + Buffer.from(`${config.appKey}:`).toString('base64');

  return {
    async sign(request) {
      const placeholders = mapRequestToPlaceholders(request);
      const createUrl = `${baseUrl}/templates/${encodeURIComponent(config.templateId)}/pass`;

      const createResponse = await fetchImpl(createUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: authHeader,
        },
        body: JSON.stringify(placeholders),
      });

      if (!createResponse.ok) {
        const body = await createResponse.text();
        throw new Error(
          `PassSlot create-pass failed (${createResponse.status}): ${body}`,
        );
      }

      const meta = (await createResponse.json()) as CreatePassResponse;
      if (!meta.passTypeIdentifier || !meta.serialNumber) {
        throw new Error(
          'PassSlot create-pass response missing passTypeIdentifier or serialNumber',
        );
      }

      // PassSlot also returns a `url` in the create response, but that's a
      // user-facing landing page (different host, HTML), not the binary.
      // The API endpoint below is the one that streams .pkpass bytes.
      const downloadUrl = `${baseUrl}/passes/${encodeURIComponent(meta.passTypeIdentifier)}/${encodeURIComponent(meta.serialNumber)}`;

      const downloadResponse = await fetchImpl(downloadUrl, {
        headers: { Authorization: authHeader },
      });

      if (!downloadResponse.ok) {
        const body = await downloadResponse.text();
        throw new Error(
          `PassSlot download-pass failed (${downloadResponse.status}): ${body}`,
        );
      }

      const arrayBuffer = await downloadResponse.arrayBuffer();
      return Buffer.from(arrayBuffer);
    },
  };
};

export const mapRequestToPlaceholders = (
  request: PassRequest,
): Record<string, string> => ({
  label: request.label,
  description: request.description,
  passType: request.type,
  barcodeMessage: request.barcode.message,
  barcodeAltText: request.barcode.altText ?? '',
});
