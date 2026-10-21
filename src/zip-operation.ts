import type { PluginListenerHandle } from '@capacitor/core';

import type { CapacitorZipPlugin, UnzipOptions, ZipOptions, ZipProgressEvent } from './definitions';

export type ZipNativeCallOptions = Omit<ZipOptions, 'onProgress'> & { operationId: string };
export type UnzipNativeCallOptions = Omit<UnzipOptions, 'onProgress'> & { operationId: string };

type ZipCallOptions = ZipOptions & { operationId?: string };
type UnzipCallOptions = UnzipOptions & { operationId?: string };

export function createZipOperationId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `zip-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export async function runZipOrUnzip(
  plugin: Pick<CapacitorZipPlugin, 'zip' | 'unzip' | 'addListener'>,
  method: 'zip',
  options: ZipCallOptions,
): Promise<void>;
export async function runZipOrUnzip(
  plugin: Pick<CapacitorZipPlugin, 'zip' | 'unzip' | 'addListener'>,
  method: 'unzip',
  options: UnzipCallOptions,
): Promise<void>;
export async function runZipOrUnzip(
  plugin: Pick<CapacitorZipPlugin, 'zip' | 'unzip' | 'addListener'>,
  method: 'zip' | 'unzip',
  options: ZipCallOptions | UnzipCallOptions,
): Promise<void> {
  const operationId = options.operationId ?? createZipOperationId();
  const { onProgress, operationId: _ignored, ...rest } = options;

  let listenerHandle: PluginListenerHandle | undefined;
  if (onProgress) {
    listenerHandle = await plugin.addListener('progress', (event: ZipProgressEvent) => {
      if (event.operationId === operationId) {
        onProgress(event);
      }
    });
  }

  const nativeOptions = { ...rest, operationId };

  try {
    if (method === 'zip') {
      await plugin.zip(nativeOptions as ZipNativeCallOptions);
    } else {
      await plugin.unzip(nativeOptions as UnzipNativeCallOptions);
    }
  } finally {
    await listenerHandle?.remove();
  }
}
