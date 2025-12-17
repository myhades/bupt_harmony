import promptAction from '@ohos.promptAction';
import { copyToClipboard, toast } from '../common/UiUtil';

@Component
export struct MorePage {
  build() {
    Column() {
      Column() {
        Image($r('app.media.startIcon'))
          .width(96)
          .height(96)
          .borderRadius(24)
          .margin({ bottom: 12 });

        Text($r('app.string.app_name'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 4 });

        Text($r('app.string.more_subtitle'))
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'));
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 24, bottom: 24 });

      Column() {
        this.SettingsRow($r('app.string.action_share_app'), async () => {
          try {
            await copyToClipboard(this.s($r('app.string.share_text')));
            toast(this.s($r('app.string.toast_share_copied')));
          } catch (_) {
            toast(this.s($r('app.string.toast_copy_failed')));
          }
        });

        Divider().color($r('app.color.divider')).margin({ left: 14 });

        this.SettingsRow($r('app.string.action_about'), async () => {
          await this.showAbout();
        });
      }
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .padding({ top: 4, bottom: 4 })
      .width('100%');
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'));
  }

  @Builder
  SettingsRow(title: Resource, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1);

      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .opacity(0.6);
    }
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .width('100%')
    .onClick(onClick);
  }

  private async showAbout(): Promise<void> {
    try {
      await promptAction.showDialog({
        title: this.s($r('app.string.about_title')),
        message: this.s($r('app.string.about_content')),
        buttons: [{ text: this.s($r('app.string.about_ok')), color: '#007DFF' }]
      });
    } catch (_) {
      toast(this.s($r('app.string.about_content')));
    }
  }

  private s(res: Resource): string {
    return getContext(this).resourceManager.getStringSync(res);
  }
}
