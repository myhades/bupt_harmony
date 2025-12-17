import { decryptPackedV1ToText, PackedCipherTextV1 } from '../common/CryptoUtil';
import { copyToClipboard, toast } from '../common/UiUtil';

@Component
export struct DecryptPage {
  @State cipherText: string = '';
  @State passphrase: string = '';

  @State isWorking: boolean = false;
  @State outputText: string = '';
  @State errorText: string = '';

  build() {
    Column() {
      Text($r('app.string.page_decrypt_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });

      Column() {
        Text($r('app.string.label_ciphertext_input'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 6 });

        TextArea({ text: this.cipherText, placeholder: $r('app.string.placeholder_ciphertext') })
          .height(160)
          .maxLength(20000)
          .onChange((value: string) => {
            this.cipherText = value;
          });

        Row() {
          Text(`${this.cipherText.length}/20000`)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .margin({ top: 6 });

        Text($r('app.string.hint_key_derivation'))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 10, bottom: 6 });

        TextInput({ text: this.passphrase, placeholder: $r('app.string.placeholder_key') })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.passphrase = value;
          });

        Button($r('app.string.action_decrypt'))
          .margin({ top: 12 })
          .width('100%')
          .enabled(!this.isWorking)
          .onClick(async () => {
            await this.onDecrypt();
          });

        if (this.errorText.length > 0) {
          Text(this.errorText)
            .fontSize(12)
            .fontColor($r('app.color.danger'))
            .margin({ top: 8 });
        }
      }
      .padding(14)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .margin({ bottom: 12 });

      if (this.outputText.length > 0) {
        Column() {
          Row() {
            Text($r('app.string.label_plaintext_output'))
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1);

            Button($r('app.string.action_copy'))
              .type(ButtonType.Normal)
              .onClick(async () => {
                try {
                  await copyToClipboard(this.outputText);
                  toast(this.s($r('app.string.toast_copied')));
                } catch (_) {
                  toast(this.s($r('app.string.toast_copy_failed')));
                }
              });
          }
          .margin({ bottom: 8 });

          Scroll() {
            Text(this.outputText)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .lineHeight(20);
          }
          .height(160);
        }
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)
        .margin({ bottom: 12 });
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'));
  }

  private async onDecrypt(): Promise<void> {
    this.errorText = '';
    this.outputText = '';

    if (this.cipherText.trim().length === 0) {
      this.errorText = this.s($r('app.string.error_cipher_empty'));
      toast(this.errorText);
      return;
    }
    if (this.passphrase.trim().length === 0) {
      this.errorText = this.s($r('app.string.error_key_empty'));
      toast(this.errorText);
      return;
    }

    let packed: PackedCipherTextV1;
    try {
      packed = JSON.parse(this.cipherText) as PackedCipherTextV1;
    } catch (_) {
      this.errorText = this.s($r('app.string.error_cipher_format'));
      toast(this.errorText);
      return;
    }

    if (!packed || packed.v !== 1 || !packed.alg || !packed.ivHex || !packed.ctHex) {
      this.errorText = this.s($r('app.string.error_cipher_format'));
      toast(this.errorText);
      return;
    }

    try {
      this.isWorking = true;
      this.outputText = await decryptPackedV1ToText(packed, this.passphrase);
      toast(this.s($r('app.string.toast_decrypt_ok')));
    } catch (_) {
      this.errorText = this.s($r('app.string.error_decrypt_failed'));
      toast(this.errorText);
    } finally {
      this.isWorking = false;
    }
  }

  private s(res: Resource): string {
    return getContext(this).resourceManager.getStringSync(res);
  }
}
