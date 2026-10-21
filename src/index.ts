import { registerPlugin } from '@capacitor/core';

import type { CapacitorZipPlugin } from './definitions';
import { wrapCapacitorZipPlugin } from './zip-operation';

const CapacitorZipNative = registerPlugin<CapacitorZipPlugin>('CapacitorZip', {
  web: () => import('./web').then((m) => new m.CapacitorZipWeb()),
});

const CapacitorZip = wrapCapacitorZipPlugin(CapacitorZipNative);

export * from './definitions';
export { CapacitorZip };
