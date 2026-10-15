import { WebPlugin } from '@capacitor/core';
import { BlobReader, BlobWriter, ZipReader } from '@zip.js/zip.js';
import type { Entry } from '@zip.js/zip.js';

import type { CapacitorZipPlugin, UnzipOptions, ZipOptions, ZipProgressEvent } from './definitions';
import {
  computeZipProgressRatio,
  estimateUncompressedBytesLoaded,
  isZipProgressLengthComputable,
  ZipProgressEmitThrottle,
} from './progress';

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

      const fileEntries = entries.filter((entry: Entry) => !entry.directory);
      const filesTotal = fileEntries.length;
      let totalBytes = 0;
      for (const entry of fileEntries) {
        if (entry.uncompressedSize > 0) {
          totalBytes += entry.uncompressedSize;
        }
      }

      let filesCompleted = 0;
      let loadedBytes = 0;
      const throttle = new ZipProgressEmitThrottle();

      const emitProgress = (currentFile?: string, operationComplete = false) => {
        const progress = computeZipProgressRatio({
          loaded: loadedBytes,
          total: totalBytes,
          filesCompleted,
          filesTotal,
          operationComplete,
        });
        if (!throttle.shouldEmit(progress, operationComplete)) {
          return;
        }
        throttle.recordEmit(progress);

        const event: ZipProgressEvent = {
          operation: 'unzip',
          loaded: loadedBytes,
          total: totalBytes,
          progress,
          lengthComputable: isZipProgressLengthComputable(totalBytes, filesTotal),
          filesCompleted,
          filesTotal,
        };
        if (currentFile) {
          event.currentFile = currentFile;
        }
        this.notifyListeners('progress', event);
      };

      for (const entry of fileEntries) {
        const entryStartLoaded = loadedBytes;
        emitProgress(entry.filename);

        const fileBlob = await entry.getData(new BlobWriter(), {
          password: options.password,
          onprogress: (compressedLoaded: number, compressedTotal: number) => {
            const uncompressedSize = entry.uncompressedSize > 0 ? entry.uncompressedSize : 0;
            const entryLoaded = estimateUncompressedBytesLoaded(compressedLoaded, compressedTotal, uncompressedSize);
            loadedBytes = entryStartLoaded + entryLoaded;
            emitProgress(entry.filename);
          },
        });

        if (entry.uncompressedSize > 0) {
          loadedBytes = entryStartLoaded + entry.uncompressedSize;
        } else {
          loadedBytes = entryStartLoaded + fileBlob.size;
        }

        const url = URL.createObjectURL(fileBlob);

        const a = document.createElement('a');
        a.href = url;
        a.download = entry.filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        filesCompleted += 1;
        emitProgress(entry.filename);
      }

      emitProgress(undefined, true);
    } catch (error) {
      throw new Error(`Failed to unzip: ${error instanceof Error ? error.message : 'Unknown error'}`, { cause: error });
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
