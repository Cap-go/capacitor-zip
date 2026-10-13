package ee.forgr.plugin.capacitor_zip;

import java.io.File;
import java.io.IOException;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * Helpers for zip/unzip progress reporting (byte and file counts).
 */
public final class CapacitorZipProgress {

    public static final class Stats {

        public long totalBytes;
        public int filesTotal;
    }

    private CapacitorZipProgress() {}

    /**
     * Progress ratio from 0 to 1. When the operation has finished and there is no byte or file total, returns 1.
     */
    public static double computeProgress(long loaded, long total, int filesCompleted, int filesTotal, boolean operationComplete) {
        if (total > 0) {
            return Math.min(1.0, (double) loaded / total);
        }
        if (filesTotal > 0) {
            return Math.min(1.0, (double) filesCompleted / filesTotal);
        }
        if (operationComplete) {
            return 1.0;
        }
        return 0;
    }

    public static Stats computeSourceStats(File source, boolean includeParentFolder) {
        Stats stats = new Stats();
        if (!source.exists()) {
            return stats;
        }
        if (source.isDirectory()) {
            if (includeParentFolder) {
                accumulateDirectory(source, stats);
            } else {
                File[] files = source.listFiles();
                if (files != null) {
                    for (File file : files) {
                        if (file.isDirectory()) {
                            accumulateDirectory(file, stats);
                        } else {
                            stats.filesTotal++;
                            stats.totalBytes += file.length();
                        }
                    }
                }
            }
        } else {
            stats.filesTotal = 1;
            stats.totalBytes = source.length();
        }
        return stats;
    }

    public static Stats computeArchiveStats(File zipFile) throws IOException {
        Stats stats = new Stats();
        try (ZipFile archive = new ZipFile(zipFile)) {
            Enumeration<? extends ZipEntry> entries = archive.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                stats.filesTotal++;
                long size = entry.getSize();
                if (size > 0) {
                    stats.totalBytes += size;
                }
            }
        }
        return stats;
    }

    private static void accumulateDirectory(File directory, Stats stats) {
        File[] files = directory.listFiles();
        if (files == null) {
            return;
        }
        for (File file : files) {
            if (file.isDirectory()) {
                accumulateDirectory(file, stats);
            } else {
                stats.filesTotal++;
                stats.totalBytes += file.length();
            }
        }
    }
}
