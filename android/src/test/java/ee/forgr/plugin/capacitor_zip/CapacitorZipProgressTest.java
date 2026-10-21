package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import com.getcapacitor.JSObject;
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
    public void computeProgress_emptyArchiveComplete_returnsOne() {
        assertEquals(1.0, CapacitorZipProgress.computeProgress(0, 0, 0, 0, true), 0.0001);
        assertEquals(0.0, CapacitorZipProgress.computeProgress(0, 0, 0, 0, false), 0.0001);
    }

    @Test
    public void progressThrottle_skipsRapidDuplicateProgress() {
        CapacitorZipProgressThrottle throttle = new CapacitorZipProgressThrottle();
        assertTrue(throttle.shouldEmit(0.1, false));
        throttle.recordEmit(0.1);
        assertFalse(throttle.shouldEmit(0.1001, false));
        assertTrue(throttle.shouldEmit(0.5, false));
        assertTrue(throttle.shouldEmit(0.1, true));
    }

    @Test
    public void eventContext_storesOperationMetadata() {
        CapacitorZipProgress.EventContext context = new CapacitorZipProgress.EventContext("op-1", "/src", "/dest.zip");
        assertEquals("op-1", context.operationId);
        assertEquals("/src", context.source);
        assertEquals("/dest.zip", context.destination);
    }

    @Test
    public void buildProgressEvent_includesOperationMetadata() {
        CapacitorZipProgress.EventContext context = new CapacitorZipProgress.EventContext("op-1", "/src", "/dest.zip");
        JSObject data = CapacitorZipProgress.buildProgressEvent(context, "zip", 1, 10, "file.txt", 1, 5, false);
        String json = data.toString();
        assertTrue(json.contains("\"operationId\":\"op-1\""));
        assertTrue(json.contains("\"source\":\"/src\""));
        assertTrue(json.contains("\"destination\":\"/dest.zip\""));
        assertTrue(json.contains("\"operation\":\"zip\""));
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
