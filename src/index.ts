import { registerPlugin } from '@capacitor/core';

import type { CapacitorZipPlugin, UnzipOptions, ZipOptions } from './definitions';
import { runZipOrUnzip } from './zip-operation';

const CapacitorZipNative = registerPlugin<CapacitorZipPlugin>('CapacitorZip', {
  web: () => import('./web').then((m) => new m.CapacitorZipWeb()),
});

const CapacitorZip: CapacitorZipPlugin = {
  addListener: (...args) => CapacitorZipNative.addListener(...args),
  getPluginVersion: () => CapacitorZipNative.getPluginVersion(),
  zip: (options: ZipOptions) => runZipOrUnzip(CapacitorZipNative, 'zip', options),
  unzip: (options: UnzipOptions) => runZipOrUnzip(CapacitorZipNative, 'unzip', options),
};

export * from './definitions';
export { CapacitorZip };
export { createZipOperationId, runZipOrUnzip } from './zip-operation';
