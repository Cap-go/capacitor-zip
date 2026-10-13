package ee.forgr.plugin.capacitor_zip;

/**
 * Limits how often progress listeners are notified during chunked I/O.
 */
public final class CapacitorZipProgressThrottle {

    private static final long MIN_EMIT_INTERVAL_MS = 50;
    private static final double MIN_PROGRESS_DELTA = 0.005;

    private long lastEmitMs;
    private double lastProgress = -1;

    public boolean shouldEmit(double progress, boolean force) {
        if (force) {
            return true;
        }
        if (lastProgress < 0) {
            return true;
        }
        if (progress >= 1.0) {
            return true;
        }
        long now = System.currentTimeMillis();
        if (now - lastEmitMs >= MIN_EMIT_INTERVAL_MS) {
            return true;
        }
        return Math.abs(progress - lastProgress) >= MIN_PROGRESS_DELTA;
    }

    public void recordEmit(double progress) {
        lastEmitMs = System.currentTimeMillis();
        lastProgress = progress;
    }
}
