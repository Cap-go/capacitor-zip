package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class CapacitorZipProgressTest {

    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();

    @Test
    public void computeSourceStats_countsSingleFile() throws Exception {
        File file = tempFolder.newFile("one.txt");
        Files.write(file.toPath(), "hello".getBytes(StandardCharsets.UTF_8));

        CapacitorZipProgress.Stats stats = CapacitorZipProgress.computeSourceStats(file, true);
        assertEquals(1, stats.filesTotal);
        assertEquals(file.length(), stats.totalBytes);
    }

    @Test
    public void computeArchiveStats_countsZipEntries() throws Exception {
        File zip = createZipWithEntry("hello.txt", "hello");

        CapacitorZipProgress.Stats stats = CapacitorZipProgress.computeArchiveStats(zip);
        assertEquals(1, stats.filesTotal);
        assertEquals(5, stats.totalBytes);
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
