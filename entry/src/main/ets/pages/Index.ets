import { EncryptPage } from './EncryptPage';
import { DecryptPage } from './DecryptPage';
import { MorePage } from './MorePage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
      TabContent() {
        EncryptPage()
      }
      .tabBar({ text: $r('app.string.tab_encrypt'), icon: $r('app.media.tab_encrypt') })

      TabContent() {
        DecryptPage()
      }
      .tabBar({ text: $r('app.string.tab_decrypt'), icon: $r('app.media.tab_decrypt') })

      TabContent() {
        MorePage()
      }
      .tabBar({ text: $r('app.string.tab_more'), icon: $r('app.media.tab_more') })
    }
    .width('100%')
    .height('100%')
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
