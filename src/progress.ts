export interface ZipProgressRatioInput {
  loaded: number;
  total: number;
  filesCompleted: number;
  filesTotal: number;
  operationComplete?: boolean;
}

export function computeZipProgressRatio(input: ZipProgressRatioInput): number {
  const { loaded, total, filesCompleted, filesTotal, operationComplete } = input;
  if (total > 0) {
    return Math.min(1, loaded / total);
  }
  if (filesTotal > 0) {
    return Math.min(1, filesCompleted / filesTotal);
  }
  if (operationComplete) {
    return 1;
  }
  return 0;
}

export function estimateUncompressedBytesLoaded(
  compressedLoaded: number,
  compressedTotal: number,
  uncompressedSize: number,
): number {
  if (uncompressedSize <= 0 || compressedTotal <= 0) {
    return 0;
  }
  const ratio = compressedLoaded / compressedTotal;
  return Math.min(uncompressedSize, Math.round(ratio * uncompressedSize));
}

export function isZipProgressLengthComputable(total: number, filesTotal: number): boolean {
  return total > 0 || filesTotal > 0;
}

const MIN_EMIT_INTERVAL_MS = 50;
const MIN_PROGRESS_DELTA = 0.005;

export class ZipProgressEmitThrottle {
  private lastEmitMs = 0;
  private lastProgress = -1;

  shouldEmit(progress: number, force: boolean): boolean {
    if (force || this.lastProgress < 0 || progress >= 1) {
      return true;
    }
    const now = Date.now();
    if (now - this.lastEmitMs >= MIN_EMIT_INTERVAL_MS) {
      return true;
    }
    return Math.abs(progress - this.lastProgress) >= MIN_PROGRESS_DELTA;
  }

  recordEmit(progress: number): void {
    this.lastEmitMs = Date.now();
    this.lastProgress = progress;
  }
}
