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

    @Test
    public void resolveFilesystemPath_preservesPlusSignInPlainPath() {
        assertEquals("/sdcard/a+b.zip", CapacitorZipPath.resolveFilesystemPath("/sdcard/a+b.zip"));
        assertEquals("/sdcard/a+b.zip", CapacitorZipPath.resolveFilesystemPath("file:///sdcard/a%2Bb.zip"));
    }

    @Test
    public void resolveFilesystemPath_decodesPercentInFileUrlWithoutDoubleDecoding() {
        assertEquals("/sdcard/100%.zip", CapacitorZipPath.resolveFilesystemPath("file:///sdcard/100%25.zip"));
    }

    @Test
    public void resolveFilesystemPath_leavesLiteralPercentInPlainPath() {
        assertEquals("/sdcard/100%/a.zip", CapacitorZipPath.resolveFilesystemPath("/sdcard/100%/a.zip"));
    }

    @Test
    public void resolveFilesystemPath_decodesUtf8PercentSequences() {
        assertEquals("/tmp/Música/file.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/M%C3%BAsica/file.zip"));
    }

    @Test
    public void resolveFilesystemPath_leavesContentUriPercentEncodingUnchanged() {
        String contentUri = "content://com.example.provider/document/100%2Ffile";
        assertEquals(contentUri, CapacitorZipPath.resolveFilesystemPath(contentUri));
    }

    @Test
    public void resolveFilesystemPath_stripsFileSchemeWhenUriParseFails() {
        assertEquals("/tmp/my folder/file.zip", CapacitorZipPath.resolveFilesystemPath("file:///tmp/my folder/file.zip"));
    }
}
