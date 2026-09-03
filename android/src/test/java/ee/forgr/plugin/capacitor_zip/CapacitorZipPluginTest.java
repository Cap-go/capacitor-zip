package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class CapacitorZipPluginTest {

    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();

    @Test
    public void validateZipArchive_rejectsPlainTextFile() throws Exception {
        File fakeZip = tempFolder.newFile("corrupt.zip");
        Files.write(fakeZip.toPath(), "not a zip file".getBytes(StandardCharsets.UTF_8));

        IOException error = assertThrows(IOException.class, () -> CapacitorZipPlugin.validateZipArchive(fakeZip));
        assertEquals("Invalid or corrupt zip file", error.getMessage());
    }

    @Test
    public void validateZipArchive_acceptsEmptyZip() throws Exception {
        File emptyZip = createEmptyZip();

        CapacitorZipPlugin.validateZipArchive(emptyZip);
    }

    @Test
    public void unzipWithoutPassword_rejectsCorruptFile() throws Exception {
        File fakeZip = tempFolder.newFile("corrupt.zip");
        Files.write(fakeZip.toPath(), "not a zip file".getBytes(StandardCharsets.UTF_8));
        File destDir = tempFolder.newFolder("dest");

        CapacitorZipPlugin plugin = new CapacitorZipPlugin();
        Method unzip = CapacitorZipPlugin.class.getDeclaredMethod("unzipWithoutPassword", File.class, File.class);
        unzip.setAccessible(true);

        try {
            unzip.invoke(plugin, fakeZip, destDir);
            fail("Expected IOException for corrupt zip");
        } catch (Exception e) {
            assertTrue(e.getCause() instanceof IOException);
            assertEquals("Invalid or corrupt zip file", e.getCause().getMessage());
        }
    }

    @Test
    public void unzipWithoutPassword_extractsValidZip() throws Exception {
        File zipFile = createZipWithEntry("hello.txt", "hello");
        File destDir = tempFolder.newFolder("dest");

        CapacitorZipPlugin plugin = new CapacitorZipPlugin();
        Method unzip = CapacitorZipPlugin.class.getDeclaredMethod("unzipWithoutPassword", File.class, File.class);
        unzip.setAccessible(true);
        unzip.invoke(plugin, zipFile, destDir);

        File extracted = new File(destDir, "hello.txt");
        assertTrue(extracted.exists());
        assertEquals("hello", new String(Files.readAllBytes(extracted.toPath()), StandardCharsets.UTF_8));
    }

    private File createEmptyZip() throws IOException {
        File zip = tempFolder.newFile("empty.zip");
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zip))) {
            // no entries
        }
        return zip;
    }

    private File createZipWithEntry(String name, String content) throws IOException {
        File zip = tempFolder.newFile("valid.zip");
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zip))) {
            ZipEntry entry = new ZipEntry(name);
            zos.putNextEntry(entry);
            zos.write(content.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }
        return zip;
    }
}
