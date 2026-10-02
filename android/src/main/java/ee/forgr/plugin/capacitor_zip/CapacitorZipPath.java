package ee.forgr.plugin.capacitor_zip;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

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
            try {
                URI uri = new URI(trimmed);
                if ("file".equalsIgnoreCase(uri.getScheme())) {
                    String uriPath = uri.getPath();
                    if (uriPath != null && !uriPath.isEmpty()) {
                        return URLDecoder.decode(uriPath, StandardCharsets.UTF_8);
                    }
                }
            } catch (Exception ignored) {
                // fall through to return trimmed path below
            }
        }
        if (trimmed.contains("%")) {
            return URLDecoder.decode(trimmed, StandardCharsets.UTF_8);
        }
        return trimmed;
    }
}
