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
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.exception.ZipException;
import net.lingala.zip4j.model.ZipParameters;
import net.lingala.zip4j.model.enums.CompressionLevel;
import net.lingala.zip4j.model.enums.EncryptionMethod;
import net.lingala.zip4j.progress.ProgressMonitor;

@CapacitorPlugin(name = "CapacitorZip")
public class CapacitorZipPlugin extends Plugin {

    private final String pluginVersion = "8.2.2";

    @PluginMethod
    public void zip(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String password = call.getString("password");
        Boolean includeParentFolder = call.getBoolean("includeParentFolder", true);

        if (source == null || source.isEmpty()) {
            call.reject("Source path is required", CapacitorZipErrorCode.SOURCE_REQUIRED);
            return;
        }

        if (destination == null || destination.isEmpty()) {
            call.reject("Destination path is required", CapacitorZipErrorCode.DESTINATION_REQUIRED);
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

            CapacitorZipProgress.EventContext progressContext = createProgressContext(call);
            if (password != null && !password.isEmpty()) {
                zipWithPassword(sourceFile, destinationFile, password, includeParentFolder, progressContext);
            } else {
                zipWithoutPassword(sourceFile, destinationFile, includeParentFolder, progressContext);
            }

            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to create zip archive: " + e.getMessage(), CapacitorZipErrorCode.ZIP_FAILED, e);
        }
    }

    @PluginMethod
    public void unzip(PluginCall call) {
        String source = call.getString("source");
        String destination = call.getString("destination");
        String password = call.getString("password");

        if (source == null || source.isEmpty()) {
            call.reject("Source path is required", CapacitorZipErrorCode.SOURCE_REQUIRED);
            return;
        }

        if (destination == null || destination.isEmpty()) {
            call.reject("Destination path is required", CapacitorZipErrorCode.DESTINATION_REQUIRED);
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

            CapacitorZipProgress.EventContext progressContext = createProgressContext(call);
            if (password != null && !password.isEmpty()) {
                unzipWithPassword(sourceFile, destinationDir, password, progressContext);
            } else {
                unzipWithoutPassword(sourceFile, destinationDir, progressContext);
            }

            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to extract zip archive: " + e.getMessage(), CapacitorZipErrorCode.UNZIP_FAILED, e);
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

    private CapacitorZipProgress.EventContext createProgressContext(PluginCall call) {
        String operationId = call.getString("operationId");
        String source = call.getString("source");
        String destination = call.getString("destination");
        return new CapacitorZipProgress.EventContext(operationId, source, destination);
    }

    private void emitProgress(
        CapacitorZipProgress.EventContext context,
        String operation,
        long loaded,
        long total,
        String currentFile,
        Integer filesCompleted,
        Integer filesTotal,
        boolean operationComplete
    ) {
        if (getBridge() == null) {
            return;
        }
        JSObject data = CapacitorZipProgress.buildProgressEvent(
            context,
            operation,
            loaded,
            total,
            currentFile,
            filesCompleted,
            filesTotal,
            operationComplete
        );
        notifyListeners("progress", data);
    }

    private void runZip4jWithProgress(CapacitorZipProgress.EventContext context, String operation, ZipFile zipFile, Zip4jWork work)
        throws Exception {
        zipFile.setRunInThread(true);
        work.run();
        ProgressMonitor monitor = zipFile.getProgressMonitor();
        while (monitor.getState() == ProgressMonitor.State.BUSY) {
            emitFromZip4jMonitor(context, operation, monitor, false);
            try {
                Thread.sleep(16);
            } catch (InterruptedException e) {
                monitor.setCancelAllTasks(true);
                Thread.currentThread().interrupt();
                throw e;
            }
        }
        emitFromZip4jMonitor(context, operation, monitor, true);
        if (monitor.getResult() == ProgressMonitor.Result.ERROR) {
            Exception cause = monitor.getException();
            if (cause instanceof Exception) {
                throw (Exception) cause;
            }
            throw new ZipException(cause != null ? cause.getMessage() : "Zip operation failed");
        }
    }

    private void emitFromZip4jMonitor(
        CapacitorZipProgress.EventContext context,
        String operation,
        ProgressMonitor monitor,
        boolean operationComplete
    ) {
        long total = monitor.getTotalWork();
        long loaded = monitor.getWorkCompleted();
        String fileName = monitor.getFileName();
        emitProgress(context, operation, loaded, total, fileName, null, null, operationComplete);
    }

    private interface Zip4jWork {
        void run() throws Exception;
    }

    private void zipWithPassword(
        File source,
        File destination,
        String password,
        boolean includeParentFolder,
        CapacitorZipProgress.EventContext progressContext
    ) throws Exception {
        ZipFile zipFile = new ZipFile(destination);

        ZipParameters zipParameters = new ZipParameters();
        zipParameters.setEncryptFiles(true);
        zipParameters.setEncryptionMethod(EncryptionMethod.AES);
        zipParameters.setCompressionLevel(CompressionLevel.NORMAL);

        zipFile.setPassword(password.toCharArray());

        if (source.isDirectory()) {
            if (includeParentFolder) {
                runZip4jWithProgress(progressContext, "zip", zipFile, () -> zipFile.addFolder(source, zipParameters));
            } else {
                File[] files = listDirectoryEntries(source);
                if (files.length > 0) {
                    Arrays.sort(files);
                    for (File file : files) {
                        runZip4jWithProgress(progressContext, "zip", zipFile, () -> {
                            if (file.isDirectory()) {
                                zipFile.addFolder(file, zipParameters);
                            } else {
                                zipFile.addFile(file, zipParameters);
                            }
                        });
                    }
                } else {
                    emitProgress(progressContext, "zip", 0, 0, null, null, null, true);
                }
            }
        } else {
            runZip4jWithProgress(progressContext, "zip", zipFile, () -> zipFile.addFile(source, zipParameters));
        }
    }

    private void zipWithoutPassword(
        File source,
        File destination,
        boolean includeParentFolder,
        CapacitorZipProgress.EventContext progressContext
    ) throws IOException {
        CapacitorZipProgress.Stats stats = CapacitorZipProgress.computeSourceStats(source, includeParentFolder);
        ProgressTracker tracker = new ProgressTracker(progressContext, "zip", stats);

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

            byte[] buffer = new byte[CapacitorZipIO.BUFFER_BYTES];
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
        try (java.util.zip.ZipFile zipFile = new java.util.zip.ZipFile(source)) {
            zipFile.entries();
        } catch (java.util.zip.ZipException e) {
            throw new IOException("Invalid or corrupt zip file", e);
        }
    }

    private void unzipWithPassword(File source, File destination, String password, CapacitorZipProgress.EventContext progressContext)
        throws Exception {
        validateZipArchive(source);
        ZipFile zipFile = new ZipFile(source);
        if (zipFile.isEncrypted()) {
            zipFile.setPassword(password.toCharArray());
        }
        runZip4jWithProgress(progressContext, "unzip", zipFile, () -> zipFile.extractAll(destination.getAbsolutePath()));
    }

    private void unzipWithoutPassword(File source, File destination, CapacitorZipProgress.EventContext progressContext) throws IOException {
        try (java.util.zip.ZipFile zipFile = new java.util.zip.ZipFile(source)) {
            CapacitorZipProgress.Stats stats = new CapacitorZipProgress.Stats();
            List<ZipEntry> entryList = new ArrayList<>();
            java.util.Enumeration<? extends ZipEntry> entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                entryList.add(entry);
                stats.filesTotal++;
                long size = entry.getSize();
                if (size > 0) {
                    stats.totalBytes += size;
                }
            }

            ProgressTracker tracker = new ProgressTracker(progressContext, "unzip", stats);
            byte[] buffer = new byte[CapacitorZipIO.BUFFER_BYTES];

            for (ZipEntry entry : entryList) {
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
                    tracker.completeFile();
                    continue;
                }

                File parent = newFile.getParentFile();
                if (parent != null && !parent.exists()) {
                    parent.mkdirs();
                }

                try (
                    java.io.InputStream entryStream = zipFile.getInputStream(entry);
                    BufferedInputStream bis = new BufferedInputStream(entryStream);
                    FileOutputStream fos = new FileOutputStream(newFile);
                    BufferedOutputStream bos = new BufferedOutputStream(fos)
                ) {
                    int length;
                    while ((length = bis.read(buffer)) > 0) {
                        bos.write(buffer, 0, length);
                        tracker.addLoaded(length);
                    }
                }
                tracker.completeFile();
            }

            tracker.emitComplete();
        } catch (java.util.zip.ZipException e) {
            throw new IOException("Invalid or corrupt zip file", e);
        }
    }

    private final class ProgressTracker {

        private final CapacitorZipProgress.EventContext eventContext;
        private final String operation;
        private final CapacitorZipProgress.Stats stats;
        private final CapacitorZipProgressThrottle throttle = new CapacitorZipProgressThrottle();
        private long loaded;
        private int filesCompleted;
        private String currentFile;

        ProgressTracker(CapacitorZipProgress.EventContext eventContext, String operation, CapacitorZipProgress.Stats stats) {
            this.eventContext = eventContext;
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
            emitProgress(eventContext, operation, loaded, stats.totalBytes, currentFile, filesCompleted, stats.filesTotal, force);
        }
    }
}
