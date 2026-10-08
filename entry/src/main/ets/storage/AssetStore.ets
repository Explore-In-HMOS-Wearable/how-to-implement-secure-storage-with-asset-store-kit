import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

function toBytes(value: string): Uint8Array {
  return new util.TextEncoder().encodeInto(value);
}

function toText(bytes: Uint8Array): string {
  return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(bytes);
}

export class AssetStore {
  /** Stores a secret under the alias, replacing any existing value. */
  static async saveSecret(alias: string, secret: string): Promise<void> {
    try {
      await asset.add(AssetStore.buildAsset(alias, secret));
    } catch (err) {
      const e = err as BusinessError;
      // asset.add rejects an existing alias with DUPLICATED — update it in place.
      if (e.code === asset.ErrorCode.DUPLICATED) {
        await AssetStore.updateSecret(alias, secret);
      } else {
        throw new Error(`saveSecret failed: ${e.code} - ${e.message}`);
      }
    }
  }

  /** Returns the secret stored under the alias, or undefined when none exists. */
  static async getSecret(alias: string): Promise<string | undefined> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, toBytes(alias));
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    try {
      const results = await asset.query(query);
      if (results.length === 0) {
        return undefined;
      }
      const secret = results[0].get(asset.Tag.SECRET) as Uint8Array | undefined;
      return secret === undefined ? undefined : toText(secret);
    } catch (err) {
      const e = err as BusinessError;
      if (e.code === asset.ErrorCode.NOT_FOUND) {
        return undefined;
      }
      throw new Error(`getSecret failed: ${e.code} - ${e.message}`);
    }
  }

  /** Deletes the secret stored under the alias (a no-op when none exists). */
  static async removeSecret(alias: string): Promise<void> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, toBytes(alias));
    try {
      await asset.remove(query);
    } catch (err) {
      const e = err as BusinessError;
      if (e.code !== asset.ErrorCode.NOT_FOUND) {
        throw new Error(`removeSecret failed: ${e.code} - ${e.message}`);
      }
    }
  }

  /** Updates an existing secret in place; returns false when the alias is absent. */
  static async updateSecret(alias: string, secret: string): Promise<boolean> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, toBytes(alias));

    // Only the changed attributes go here (the SECRET); the ALIAS stays in the query.
    const attributesToUpdate: asset.AssetMap = new Map();
    attributesToUpdate.set(asset.Tag.SECRET, toBytes(secret));

    try {
      await asset.update(query, attributesToUpdate);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      if (e.code === asset.ErrorCode.NOT_FOUND) {
        return false;
      }
      throw new Error(`updateSecret failed: ${e.code} - ${e.message}`);
    }
  }

  private static buildAsset(alias: string, secret: string): asset.AssetMap {
    const attributes: asset.AssetMap = new Map();
    attributes.set(asset.Tag.ALIAS, toBytes(alias));
    attributes.set(asset.Tag.SECRET, toBytes(secret));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    return attributes;
  }
}
