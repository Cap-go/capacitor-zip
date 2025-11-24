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
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;
import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.model.ZipParameters;
import net.lingala.zip4j.model.enums.CompressionLevel;
import net.lingala.zip4j.model.enums.EncryptionMethod;

@CapacitorPlugin(name = "CapacitorZip")
public class CapacitorZipPlugin extends Plugin {

    private final String pluginVersion = "7.0.2";

    @PluginMethod
    public void zip(PluginCall call) {
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
            File sourceFile = new File(source);
            if (!sourceFile.exists()) {
                call.reject("Source path does not exist");
                return;
            }

            File destinationFile = new File(destination);
            File parentDir = destinationFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }

            if (password != null && !password.isEmpty()) {
                // Use zip4j for password-protected archives
                zipWithPassword(sourceFile, destinationFile, password);
            } else {
                // Use standard Java zip for non-encrypted archives
                zipWithoutPassword(sourceFile, destinationFile);
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
            File sourceFile = new File(source);
            if (!sourceFile.exists()) {
                call.reject("Source zip file does not exist");
                return;
            }

            File destinationDir = new File(destination);
            if (!destinationDir.exists()) {
                destinationDir.mkdirs();
            }

            if (password != null && !password.isEmpty()) {
                // Use zip4j for password-protected archives
                unzipWithPassword(sourceFile, destinationDir, password);
            } else {
                // Use standard Java unzip for non-encrypted archives
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

    private void zipWithPassword(File source, File destination, String password) throws Exception {
        ZipFile zipFile = new ZipFile(destination);

        ZipParameters zipParameters = new ZipParameters();
        zipParameters.setEncryptFiles(true);
        zipParameters.setEncryptionMethod(EncryptionMethod.AES);
        zipParameters.setCompressionLevel(CompressionLevel.NORMAL);

        zipFile.setPassword(password.toCharArray());

        if (source.isDirectory()) {
            zipFile.addFolder(source, zipParameters);
        } else {
            zipFile.addFile(source, zipParameters);
        }
    }

    private void zipWithoutPassword(File source, File destination) throws IOException {
        try (
            FileOutputStream fos = new FileOutputStream(destination);
            BufferedOutputStream bos = new BufferedOutputStream(fos);
            ZipOutputStream zos = new ZipOutputStream(bos)
        ) {
            if (source.isDirectory()) {
                zipDirectory(source, source.getName(), zos);
            } else {
                zipFile(source, source.getName(), zos);
            }
        }
    }

    private void zipDirectory(File directory, String parentPath, ZipOutputStream zos) throws IOException {
        File[] files = directory.listFiles();
        if (files == null) return;

        for (File file : files) {
            if (file.isDirectory()) {
                zipDirectory(file, parentPath + "/" + file.getName(), zos);
            } else {
                zipFile(file, parentPath + "/" + file.getName(), zos);
            }
        }
    }

    private void zipFile(File file, String entryName, ZipOutputStream zos) throws IOException {
        try (FileInputStream fis = new FileInputStream(file); BufferedInputStream bis = new BufferedInputStream(fis)) {
            ZipEntry zipEntry = new ZipEntry(entryName);
            zos.putNextEntry(zipEntry);

            byte[] buffer = new byte[8192];
            int length;
            while ((length = bis.read(buffer)) > 0) {
                zos.write(buffer, 0, length);
            }

            zos.closeEntry();
        }
    }

    private void unzipWithPassword(File source, File destination, String password) throws Exception {
        ZipFile zipFile = new ZipFile(source);
        if (zipFile.isEncrypted()) {
            zipFile.setPassword(password.toCharArray());
        }
        zipFile.extractAll(destination.getAbsolutePath());
    }

    private void unzipWithoutPassword(File source, File destination) throws IOException {
        try (
            FileInputStream fis = new FileInputStream(source);
            BufferedInputStream bis = new BufferedInputStream(fis);
            ZipInputStream zis = new ZipInputStream(bis)
        ) {
            ZipEntry entry;
            byte[] buffer = new byte[8192];

            while ((entry = zis.getNextEntry()) != null) {
                File newFile = new File(destination, entry.getName());

                // Prevent zip slip vulnerability
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
                        }
                    }
                }

                zis.closeEntry();
            }
        }
    }
}
