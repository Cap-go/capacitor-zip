package ee.forgr.plugin.capacitor_zip;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;
import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.exception.ZipException;
import net.lingala.zip4j.model.ZipParameters;
import net.lingala.zip4j.model.enums.CompressionLevel;
import net.lingala.zip4j.model.enums.EncryptionMethod;
import net.lingala.zip4j.progress.ProgressMonitor;

@CapacitorPlugin(name = "CapacitorZip")
public class CapacitorZipPlugin extends Plugin {

    private final String pluginVersion = "8.2.0";

    @PluginMethod
    public void zip(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String password = call.getString("password");
        Boolean includeParentFolder = call.getBoolean("includeParentFolder", true);

        if (source == null || source.isEmpty()) {
            call.reject("Source path is required");
            return;
        }

        if (destination == null || destination.isEmpty()) {
            call.reject("Destination path is required");
            return;
        }

        try {
            String resolvedSource = CapacitorZipPath.resolveFilesystemPath(source);
            String resolvedDestination = CapacitorZipPath.resolveFilesystemPath(destination);
            File sourceFile = new File(resolvedSource);
            if (!sourceFile.exists()) {
                call.reject("Source path does not exist");
                return;
            }

            File destinationFile = new File(resolvedDestination);
            File parentDir = destinationFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }

            if (password != null && !password.isEmpty()) {
                zipWithPassword(sourceFile, destinationFile, password, includeParentFolder);
            } else {
                zipWithoutPassword(sourceFile, destinationFile, includeParentFolder);
            }

            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to create zip archive: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void unzip(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String password = call.getString("password");

        if (source == null || source.isEmpty()) {
            call.reject("Source path is required");
            return;
        }

        if (destination == null || destination.isEmpty()) {
            call.reject("Destination path is required");
            return;
        }

        try {
            String resolvedSource = CapacitorZipPath.resolveFilesystemPath(source);
            String resolvedDestination = CapacitorZipPath.resolveFilesystemPath(destination);
            File sourceFile = new File(resolvedSource);
            if (!sourceFile.exists()) {
                call.reject("Source zip file does not exist");
                return;
            }

            File destinationDir = new File(resolvedDestination);
            if (!destinationDir.exists()) {
                destinationDir.mkdirs();
            }

            if (password != null && !password.isEmpty()) {
                unzipWithPassword(sourceFile, destinationDir, password);
            } else {
                unzipWithoutPassword(sourceFile, destinationDir);
            }

            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to extract zip archive: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void getPluginVersion(final PluginCall call) {
        try {
            final JSObject ret = new JSObject();
            ret.put("version", this.pluginVersion);
            call.resolve(ret);
        } catch (final Exception e) {
            call.reject("Could not get plugin version", e);
        }
    }

    private void emitProgress(
        String operation,
        long loaded,
        long total,
        String currentFile,
        Integer filesCompleted,
        Integer filesTotal,
        boolean operationComplete
    ) {
        int filesDone = filesCompleted != null ? filesCompleted : 0;
        int filesMax = filesTotal != null ? filesTotal : 0;
        double progress = CapacitorZipProgress.computeProgress(loaded, total, filesDone, filesMax, operationComplete);

        JSObject data = new JSObject();
        data.put("operation", operation);
        data.put("loaded", loaded);
        data.put("total", total);
        data.put("progress", progress);
        data.put("lengthComputable", total > 0 || filesMax > 0);

        if (currentFile != null && !currentFile.isEmpty()) {
            data.put("currentFile", currentFile);
        }
        if (filesCompleted != null) {
            data.put("filesCompleted", filesCompleted);
        }
        if (filesTotal != null) {
            data.put("filesTotal", filesTotal);
        }

        if (getBridge() == null) {
            return;
        }
        notifyListeners("progress", data);
    }

    private void runZip4jWithProgress(String operation, ZipFile zipFile, Zip4jWork work) throws Exception {
        zipFile.setRunInThread(true);
        work.run();
        ProgressMonitor monitor = zipFile.getProgressMonitor();
        while (monitor.getState() == ProgressMonitor.State.BUSY) {
            emitFromZip4jMonitor(operation, monitor, false);
            try {
                Thread.sleep(16);
            } catch (InterruptedException e) {
                monitor.setCancelAllTasks(true);
                Thread.currentThread().interrupt();
                throw e;
            }
        }
        emitFromZip4jMonitor(operation, monitor, true);
        if (monitor.getResult() == ProgressMonitor.Result.ERROR) {
            Exception cause = monitor.getException();
            if (cause instanceof Exception) {
                throw (Exception) cause;
            }
            throw new ZipException(cause != null ? cause.getMessage() : "Zip operation failed");
        }
    }

    private void emitFromZip4jMonitor(String operation, ProgressMonitor monitor, boolean operationComplete) {
        long total = monitor.getTotalWork();
        long loaded = monitor.getWorkCompleted();
        String fileName = monitor.getFileName();
        emitProgress(operation, loaded, total, fileName, null, null, operationComplete);
    }

    private interface Zip4jWork {
        void run() throws Exception;
    }

    private void zipWithPassword(File source, File destination, String password, boolean includeParentFolder) throws Exception {
        ZipFile zipFile = new ZipFile(destination);

        ZipParameters zipParameters = new ZipParameters();
        zipParameters.setEncryptFiles(true);
        zipParameters.setEncryptionMethod(EncryptionMethod.AES);
        zipParameters.setCompressionLevel(CompressionLevel.NORMAL);

        zipFile.setPassword(password.toCharArray());

        if (source.isDirectory()) {
            if (includeParentFolder) {
                runZip4jWithProgress("zip", zipFile, () -> zipFile.addFolder(source, zipParameters));
            } else {
                File[] files = listDirectoryEntries(source);
                if (files.length > 0) {
                    Arrays.sort(files);
                    for (File file : files) {
                        runZip4jWithProgress("zip", zipFile, () -> {
                            if (file.isDirectory()) {
                                zipFile.addFolder(file, zipParameters);
                            } else {
                                zipFile.addFile(file, zipParameters);
                            }
                        });
                    }
                } else {
                    emitProgress("zip", 0, 0, null, null, null, true);
                }
            }
        } else {
            runZip4jWithProgress("zip", zipFile, () -> zipFile.addFile(source, zipParameters));
        }
    }

    private void zipWithoutPassword(File source, File destination, boolean includeParentFolder) throws IOException {
        CapacitorZipProgress.Stats stats = CapacitorZipProgress.computeSourceStats(source, includeParentFolder);
        ProgressTracker tracker = new ProgressTracker("zip", stats);

        try (
            FileOutputStream fos = new FileOutputStream(destination);
            BufferedOutputStream bos = new BufferedOutputStream(fos);
            ZipOutputStream zos = new ZipOutputStream(bos)
        ) {
            if (source.isDirectory()) {
                if (includeParentFolder) {
                    zipDirectory(source, source.getName(), zos, tracker);
                } else {
                    File[] files = listDirectoryEntries(source);
                    Arrays.sort(files);
                    for (File file : files) {
                        if (file.isDirectory()) {
                            zipDirectory(file, file.getName(), zos, tracker);
                        } else {
                            zipFile(file, file.getName(), zos, tracker);
                        }
                    }
                }
            } else {
                zipFile(source, source.getName(), zos, tracker);
            }
        }

        tracker.emitComplete();
    }

    private static File[] listDirectoryEntries(File directory) throws IOException {
        File[] files = directory.listFiles();
        if (files == null) {
            throw new IOException("Failed to list directory contents: " + directory.getAbsolutePath());
        }
        return files;
    }

    private void zipDirectory(File directory, String parentPath, ZipOutputStream zos, ProgressTracker tracker) throws IOException {
        File[] files = listDirectoryEntries(directory);

        Arrays.sort(files);
        for (File file : files) {
            if (file.isDirectory()) {
                zipDirectory(file, parentPath + "/" + file.getName(), zos, tracker);
            } else {
                zipFile(file, parentPath + "/" + file.getName(), zos, tracker);
            }
        }
    }

    private void zipFile(File file, String entryName, ZipOutputStream zos, ProgressTracker tracker) throws IOException {
        tracker.emitCurrentFile(entryName);
        try (FileInputStream fis = new FileInputStream(file); BufferedInputStream bis = new BufferedInputStream(fis)) {
            ZipEntry zipEntry = new ZipEntry(entryName);
            zos.putNextEntry(zipEntry);

            byte[] buffer = new byte[8192];
            int length;
            while ((length = bis.read(buffer)) > 0) {
                zos.write(buffer, 0, length);
                tracker.addLoaded(length);
            }

            zos.closeEntry();
        }
        tracker.completeFile();
    }

    static void validateZipArchive(File source) throws IOException {
        try (ZipFile zipFile = new ZipFile(source)) {
            if (!zipFile.isValidZipFile()) {
                throw new IOException("Invalid or corrupt zip file");
            }
        }
    }

    private void unzipWithPassword(File source, File destination, String password) throws Exception {
        validateZipArchive(source);
        ZipFile zipFile = new ZipFile(source);
        if (zipFile.isEncrypted()) {
            zipFile.setPassword(password.toCharArray());
        }
        runZip4jWithProgress("unzip", zipFile, () -> zipFile.extractAll(destination.getAbsolutePath()));
    }

    private void unzipWithoutPassword(File source, File destination) throws IOException {
        validateZipArchive(source);
        CapacitorZipProgress.Stats stats = CapacitorZipProgress.computeArchiveStats(source);
        ProgressTracker tracker = new ProgressTracker("unzip", stats);

        try (
            FileInputStream fis = new FileInputStream(source);
            BufferedInputStream bis = new BufferedInputStream(fis);
            ZipInputStream zis = new ZipInputStream(bis)
        ) {
            ZipEntry entry;
            byte[] buffer = new byte[8192];

            while ((entry = zis.getNextEntry()) != null) {
                String entryName = entry.getName();
                tracker.emitCurrentFile(entryName);
                File newFile = new File(destination, entryName);

                String destDirPath = destination.getCanonicalPath();
                String destFilePath = newFile.getCanonicalPath();
                if (!destFilePath.startsWith(destDirPath + File.separator)) {
                    throw new IOException("Entry is outside of the target directory");
                }

                if (entry.isDirectory()) {
                    newFile.mkdirs();
                } else {
                    File parent = newFile.getParentFile();
                    if (parent != null && !parent.exists()) {
                        parent.mkdirs();
                    }

                    try (FileOutputStream fos = new FileOutputStream(newFile); BufferedOutputStream bos = new BufferedOutputStream(fos)) {
                        int length;
                        while ((length = zis.read(buffer)) > 0) {
                            bos.write(buffer, 0, length);
                            tracker.addLoaded(length);
                        }
                    }
                }

                zis.closeEntry();
                tracker.completeFile();
            }
        }

        tracker.emitComplete();
    }

    private final class ProgressTracker {

        private final String operation;
        private final CapacitorZipProgress.Stats stats;
        private final CapacitorZipProgressThrottle throttle = new CapacitorZipProgressThrottle();
        private long loaded;
        private int filesCompleted;
        private String currentFile;

        ProgressTracker(String operation, CapacitorZipProgress.Stats stats) {
            this.operation = operation;
            this.stats = stats;
        }

        void emitCurrentFile(String file) {
            this.currentFile = file;
            emit(false);
        }

        void addLoaded(long bytes) {
            loaded += bytes;
            emit(false);
        }

        void completeFile() {
            filesCompleted++;
            emit(false);
        }

        void emitComplete() {
            if (stats.totalBytes > 0) {
                loaded = stats.totalBytes;
            }
            if (stats.filesTotal > 0) {
                filesCompleted = stats.filesTotal;
            }
            emit(true);
        }

        private void emit(boolean force) {
            double progress = CapacitorZipProgress.computeProgress(loaded, stats.totalBytes, filesCompleted, stats.filesTotal, force);
            if (!throttle.shouldEmit(progress, force)) {
                return;
            }
            throttle.recordEmit(progress);
            emitProgress(operation, loaded, stats.totalBytes, currentFile, filesCompleted, stats.filesTotal, force);
        }
    }
}
