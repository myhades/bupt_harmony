import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { utf8Decode, utf8Encode } from './EncodingUtil';

export type SymmetricAlgorithm = 'AES-256-GCM' | 'AES-256-CBC';

export interface PackedCipherTextV1 {
  v: 1;
  alg: SymmetricAlgorithm;
  ivHex: string;
  ctHex: string;
  tagHex?: string;
}

function ensureNonEmpty(text: string, code: string): void {
  if (text.trim().length === 0) {
    throw new Error(code);
  }
}

async function sha256(data: Uint8Array): Promise<Uint8Array> {
  const md = cryptoFramework.createMd('SHA256');
  await md.update({ data });
  const digest = await md.digest();
  return digest.data;
}

async function deriveAes256KeyFromPassphrase(passphrase: string): Promise<cryptoFramework.SymKey> {
  ensureNonEmpty(passphrase, 'KEY_EMPTY');
  const material = await sha256(utf8Encode(passphrase));
  const generator = cryptoFramework.createSymKeyGenerator('AES256');
  return await generator.convertKey({ data: material });
}

async function randomBytes(length: number): Promise<Uint8Array> {
  const random = cryptoFramework.createRandom();
  const out = await random.generateRandom(length);
  return out.data;
}

export async function encryptTextToPackedV1(plainText: string, passphrase: string, algorithm: SymmetricAlgorithm): Promise<PackedCipherTextV1> {
  ensureNonEmpty(plainText, 'TEXT_EMPTY');

  const key = await deriveAes256KeyFromPassphrase(passphrase);
  const plainBytes = utf8Encode(plainText);

  if (algorithm === 'AES-256-GCM') {
    const iv = await randomBytes(12);
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: new Uint8Array() },
      authTag: { data: new Uint8Array(16) }
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
    const result = await cipher.doFinal({ data: plainBytes });
    const tagHex = bytesToHex(params.authTag.data);
    return { v: 1, alg: algorithm, ivHex: bytesToHex(iv), ctHex: bytesToHex(result.data), tagHex };
  }

  const iv = await randomBytes(16);
  const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
  const params: cryptoFramework.IvParamsSpec = { algName: 'IvParamsSpec', iv: { data: iv } };
  await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
  const result = await cipher.doFinal({ data: plainBytes });
  return { v: 1, alg: algorithm, ivHex: bytesToHex(iv), ctHex: bytesToHex(result.data) };
}

export async function decryptPackedV1ToText(packed: PackedCipherTextV1, passphrase: string): Promise<string> {
  const key = await deriveAes256KeyFromPassphrase(passphrase);

  const iv = hexToBytes(packed.ivHex);
  let ctHex: string = packed.ctHex;
  let tagHex: string = packed.tagHex ?? '';

  if (packed.alg === 'AES-256-GCM' && tagHex.trim().length === 0) {
    // Backward/compat fallback: some implementations append 16-byte tag to the end of cipherText.
    // If so, split last 32 hex chars (16 bytes) as tag.
    const normalized = ctHex.trim();
    if (normalized.length > 32 && normalized.length % 2 === 0) {
      tagHex = normalized.slice(normalized.length - 32);
      ctHex = normalized.slice(0, normalized.length - 32);
    }
  }

  const ct = hexToBytes(ctHex);

  if (packed.alg === 'AES-256-GCM') {
    if (tagHex.trim().length === 0) {
      throw new Error('GCM_TAG_MISSING');
    }
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    const tagBytes = hexToBytes(tagHex);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: new Uint8Array() },
      authTag: { data: tagBytes }
    };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
    const result = await cipher.doFinal({ data: ct });
    return utf8Decode(result.data);
  }

  const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
  const params: cryptoFramework.IvParamsSpec = { algName: 'IvParamsSpec', iv: { data: iv } };
  await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
  const result = await cipher.doFinal({ data: ct });
  return utf8Decode(result.data);
}

function bytesToHex(bytes: Uint8Array): string {
  let out = '';
  for (let i = 0; i < bytes.length; i++) {
    out += (bytes[i] & 0xff).toString(16).padStart(2, '0');
  }
  return out;
}

function hexToBytes(hex: string): Uint8Array {
  const normalized = hex.trim().toLowerCase();
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
