package ee.forgr.plugin.capacitor_zip;

import android.net.Uri;

final class CapacitorZipPath {

    private CapacitorZipPath() {}

    /**
     * Resolves {@code file://} URLs and percent-encoded path segments to a filesystem path.
     * Other URI schemes (for example {@code content://}) are returned unchanged.
     */
    static String resolveFilesystemPath(String path) {
        if (path == null) {
            return null;
        }
        String trimmed = path.trim();
        if (trimmed.length() >= 5 && trimmed.regionMatches(true, 0, "file:", 0, 5)) {
            Uri uri = Uri.parse(trimmed);
            String uriPath = uri.getPath();
            if (uriPath != null && !uriPath.isEmpty()) {
                return Uri.decode(uriPath);
            }
        }
        if (trimmed.contains("%")) {
            return Uri.decode(trimmed);
        }
        return trimmed;
    }
}
