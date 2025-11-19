import { registerPlugin } from '@capacitor/core';

import type { CapacitorZipPlugin } from './definitions';

const CapacitorZip = registerPlugin<CapacitorZipPlugin>('CapacitorZip', {
  web: () => import('./web').then((m) => new m.CapacitorZipWeb()),
});

export * from './definitions';
export { CapacitorZip };
