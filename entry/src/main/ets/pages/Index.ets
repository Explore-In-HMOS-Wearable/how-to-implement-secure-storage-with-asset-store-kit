import { AssetStore } from '../storage/AssetStore';

@Entry
@ComponentV2
struct Index {
  private static readonly ALIAS: string = 'demo_secret';
  private static readonly TAG: string = 'AssetStoreGuide';
  @Local input: string = '';
  @Local status: string = 'Type a secret, then Save';

  build() {
    Column({ space: 12 }) {
      TextInput({ placeholder: 'Secret value' })
        .width('86%')
        .onChange((value: string) => {
          this.input = value;
        })

      Row({ space: 8 }) {
        Button('Save').layoutWeight(1).fontSize(13).onClick(() => {
          this.save();
        })
        Button('Update').layoutWeight(1).fontSize(13).onClick(() => {
          this.update();
        })
      }
      .width('86%')

      Row({ space: 8 }) {
        Button('Load').layoutWeight(1).fontSize(13).onClick(() => {
          this.load();
        })
        Button('Delete').layoutWeight(1).fontSize(13).onClick(() => {
          this.remove();
        })
      }
      .width('86%')

      Text(this.status)
        .fontSize(13)
        .fontColor(Color.Gray)
        .width('86%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }

  private async save(): Promise<void> {
    try {
      await AssetStore.saveSecret(Index.ALIAS, this.input);
      this.status = 'Saved securely';
    } catch (err) {
      const e = err as Error;
      console.error(`${Index.TAG} save failed: ${e.message}`);
      this.status = 'Save failed';
    }
  }

  private async update(): Promise<void> {
    try {
      const updated = await AssetStore.updateSecret(Index.ALIAS, this.input);
      this.status = updated ? 'Updated in place' : 'Nothing stored to update';
    } catch (err) {
      const e = err as Error;
      console.error(`${Index.TAG} update failed: ${e.message}`);
      this.status = 'Update failed';
    }
  }

  private async load(): Promise<void> {
    try {
      const secret = await AssetStore.getSecret(Index.ALIAS);
      this.status = secret === undefined ? 'Nothing stored yet' : `Loaded: ${secret}`;
    } catch (err) {
      const e = err as Error;
      console.error(`${Index.TAG} load failed: ${e.message}`);
      this.status = 'Load failed';
    }
  }

  private async remove(): Promise<void> {
    try {
      await AssetStore.removeSecret(Index.ALIAS);
      this.status = 'Deleted';
    } catch (err) {
      const e = err as Error;
      console.error(`${Index.TAG} delete failed: ${e.message}`);
      this.status = 'Delete failed';
    }
  }
}