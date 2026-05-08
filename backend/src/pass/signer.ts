export type PassType =
  | 'storeCard'
  | 'generic'
  | 'coupon'
  | 'eventTicket'
  | 'boardingPass';

export type BarcodeFormat = 'qr' | 'pdf417' | 'aztec' | 'code128';

export type PassRequest = {
  type: PassType;
  label: string;
  description: string;
  colors: {
    background: string;
    foreground: string;
    label: string;
  };
  barcode: {
    format: BarcodeFormat;
    message: string;
    altText?: string;
  };
};

export type Signer = {
  sign(request: PassRequest): Promise<Buffer>;
};
