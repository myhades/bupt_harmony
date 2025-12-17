import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';

export function toast(message: string): void {
  try {
    promptAction.showToast({ message });
  } catch (_) {
  }
}

export async function copyToClipboard(text: string): Promise<void> {
  const pb = pasteboard.getSystemPasteboard();
  const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
  try {
    await pb.setData(data);
  } catch (e) {
    throw new Error(`CLIPBOARD_FAILED:${(e as object).toString()}`);
  }
}
