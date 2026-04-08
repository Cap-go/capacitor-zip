import { WebPlugin } from '@capacitor/core';
import { BlobReader, BlobWriter, ZipReader } from '@zip.js/zip.js';
import type { Entry } from '@zip.js/zip.js';

import type { CapacitorZipPlugin, UnzipOptions, ZipOptions } from './definitions';

export class CapacitorZipWeb extends WebPlugin implements CapacitorZipPlugin {
  async zip(_options: ZipOptions): Promise<void> {
    throw new Error(
      'Zip functionality is not supported on the web platform. Use the File System API or a server-side solution.',
    );
  }

  async unzip(options: UnzipOptions): Promise<void> {
    let zipReader: ZipReader<unknown> | undefined;

    try {
      const response = await fetch(options.source);
      const blob = await response.blob();

      zipReader = new ZipReader(new BlobReader(blob));
      const entries = await zipReader.getEntries();

      const downloads = entries.map(async (entry: Entry) => {
        if (entry.directory) {
          return;
        }

        const blob = await entry.getData(new BlobWriter(), {
          password: options.password,
        });
        const url = URL.createObjectURL(blob);

        const a = document.createElement('a');
        a.href = url;
        a.download = entry.filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      });

      await Promise.all(downloads);
    } catch (error) {
      throw new Error(`Failed to unzip: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      if (zipReader) {
        await zipReader.close();
      }
    }
  }

  async getPluginVersion(): Promise<{ version: string }> {
    return { version: '7.0.0' };
  }
}
