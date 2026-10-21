import { registerPlugin } from '@capacitor/core';

import type { CapacitorZipPlugin, UnzipOptions, ZipOptions } from './definitions';
import { runZipOrUnzip } from './zip-operation';

const CapacitorZipNative = registerPlugin<CapacitorZipPlugin>('CapacitorZip', {
  web: () => import('./web').then((m) => new m.CapacitorZipWeb()),
});

const CapacitorZip = new Proxy(CapacitorZipNative, {
  get(target, prop, receiver) {
    if (prop === 'zip') {
      return (options: ZipOptions) => runZipOrUnzip(CapacitorZipNative, 'zip', options);
    }
    if (prop === 'unzip') {
      return (options: UnzipOptions) => runZipOrUnzip(CapacitorZipNative, 'unzip', options);
    }
    return Reflect.get(target, prop, receiver);
  },
}) as CapacitorZipPlugin;

export * from './definitions';
export { CapacitorZip };
