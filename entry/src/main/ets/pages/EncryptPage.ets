import { encryptTextToPackedV1, SymmetricAlgorithm } from '../common/CryptoUtil';
import { copyToClipboard, toast } from '../common/UiUtil';

@Component
export struct EncryptPage {
  @State plainText: string = '';
  @State passphrase: string = '';
  @State algorithm: SymmetricAlgorithm = 'AES-256-GCM';

  @State isWorking: boolean = false;
  @State outputText: string = '';
  @State errorText: string = '';

  build() {
    Column() {
      Text($r('app.string.page_encrypt_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });

      Column() {
        Text($r('app.string.label_plaintext'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 6 });

        TextArea({ text: this.plainText, placeholder: $r('app.string.placeholder_plaintext') })
          .height(140)
          .maxLength(5000)
          .onChange((value: string) => {
            this.plainText = value;
          });

        Row() {
          Text(`${this.plainText.length}/5000`)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .margin({ top: 6 });
      }
      .padding(14)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .margin({ bottom: 12 });

      Column() {
        Text($r('app.string.label_algorithm'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 6 });

        Row() {
          Button($r('app.string.alg_aes_gcm'))
            .type(ButtonType.Normal)
            .margin({ right: 10 })
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.algorithm === 'AES-256-GCM' ? $r('app.color.chip_selected_bg') : $r('app.color.chip_bg'))
            .fontColor(this.algorithm === 'AES-256-GCM' ? $r('app.color.chip_selected_text') : $r('app.color.text_primary'))
            .borderRadius(999)
            .onClick(() => {
              this.algorithm = 'AES-256-GCM';
            });

          Button($r('app.string.alg_aes_cbc'))
            .type(ButtonType.Normal)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.algorithm === 'AES-256-CBC' ? $r('app.color.chip_selected_bg') : $r('app.color.chip_bg'))
            .fontColor(this.algorithm === 'AES-256-CBC' ? $r('app.color.chip_selected_text') : $r('app.color.text_primary'))
            .borderRadius(999)
            .onClick(() => {
              this.algorithm = 'AES-256-CBC';
            });
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);

        Text($r('app.string.hint_key_derivation'))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 10, bottom: 6 });

        TextInput({ text: this.passphrase, placeholder: $r('app.string.placeholder_key') })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.passphrase = value;
          });

        Button($r('app.string.action_encrypt'))
          .margin({ top: 12 })
          .width('100%')
          .enabled(!this.isWorking)
          .onClick(async () => {
            await this.onEncrypt();
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
            Text($r('app.string.label_ciphertext'))
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

  private async onEncrypt(): Promise<void> {
    this.errorText = '';
    this.outputText = '';

    if (this.plainText.trim().length === 0) {
      this.errorText = this.s($r('app.string.error_text_empty'));
      toast(this.errorText);
      return;
    }
    if (this.passphrase.trim().length === 0) {
      this.errorText = this.s($r('app.string.error_key_empty'));
      toast(this.errorText);
      return;
    }
    if (this.passphrase.length < 6) {
      this.errorText = this.s($r('app.string.error_key_too_short'));
      toast(this.errorText);
      return;
    }

    try {
      this.isWorking = true;
      const packed = await encryptTextToPackedV1(this.plainText, this.passphrase, this.algorithm);
      this.outputText = JSON.stringify(packed);
      toast(this.s($r('app.string.toast_encrypt_ok')));
    } catch (_) {
      this.errorText = this.s($r('app.string.toast_encrypt_failed'));
      toast(this.errorText);
    } finally {
      this.isWorking = false;
    }
  }

  private s(res: Resource): string {
    return getContext(this).resourceManager.getStringSync(res);
  }
}
