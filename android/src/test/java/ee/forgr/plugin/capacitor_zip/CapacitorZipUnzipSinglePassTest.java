package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.FileOutputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class CapacitorZipUnzipSinglePassTest {

    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();

    @Test
    public void unzipWithoutPassword_usesJdkZipFileSingleOpen() throws Exception {
        File zipFile = tempFolder.newFile("valid.zip");
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zipFile))) {
            ZipEntry entry = new ZipEntry("hello.txt");
            zos.putNextEntry(entry);
            zos.write("hello".getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        File destDir = tempFolder.newFolder("dest");
        CapacitorZipPlugin plugin = new CapacitorZipPlugin();
        Method unzip = CapacitorZipPlugin.class.getDeclaredMethod("unzipWithoutPassword", File.class, File.class);
        unzip.setAccessible(true);
        unzip.invoke(plugin, zipFile, destDir);

        File extracted = new File(destDir, "hello.txt");
        assertTrue(extracted.exists());
        assertEquals("hello", Files.readString(extracted.toPath()));
    }
}
