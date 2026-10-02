package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class CapacitorZipPathTest {

    @Test
    public void resolveFilesystemPath_leavesAbsolutePathUnchanged() {
        assertEquals("/data/local/tmp/archive.zip", CapacitorZipPath.resolveFilesystemPath("/data/local/tmp/archive.zip"));
    }

    @Test
    public void resolveFilesystemPath_convertsFileUrl() {
        assertEquals(
            "/storage/emulated/0/Download/archive.zip",
            CapacitorZipPath.resolveFilesystemPath("file:///storage/emulated/0/Download/archive.zip")
        );
    }

    @Test
    public void resolveFilesystemPath_decodesPercentEncoding() {
        assertEquals("/tmp/my folder/file.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/my%20folder/file.zip"));
        assertEquals("/tmp/my folder/file.zip", CapacitorZipPath.resolveFilesystemPath("file:///tmp/my%20folder/file.zip"));
    }

    @Test
    public void resolveFilesystemPath_leavesContentUriUnchanged() {
        String contentUri = "content://com.example.provider/document/123";
        assertEquals(contentUri, CapacitorZipPath.resolveFilesystemPath(contentUri));
    }
}
