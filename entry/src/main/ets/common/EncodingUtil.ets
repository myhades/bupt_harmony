import { util } from '@kit.ArkTS';

export function utf8Encode(text: string): Uint8Array {
  return util.TextEncoder.create('utf-8').encodeInto(text);
}

export function utf8Decode(bytes: Uint8Array): string {
  return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(bytes);
}

export function hexEncode(bytes: Uint8Array): string {
  let hex: string = '';
  for (let i = 0; i < bytes.length; i++) {
    const value = bytes[i] & 0xff;
    hex += value.toString(16).padStart(2, '0');
  }
  return hex;
}

export function hexDecode(hex: string): Uint8Array {
  const normalized = hex.trim().toLowerCase();
  if (normalized.length === 0) {
    return new Uint8Array();
  }
  if (normalized.length % 2 !== 0) {
    throw new Error('HEX_LEN_INVALID');
  }
  const out = new Uint8Array(normalized.length / 2);
  for (let i = 0; i < normalized.length; i += 2) {
    const byte = Number.parseInt(normalized.slice(i, i + 2), 16);
    if (Number.isNaN(byte)) {
      throw new Error('HEX_CHAR_INVALID');
    }
    out[i / 2] = byte;
  }
  return out;
}
