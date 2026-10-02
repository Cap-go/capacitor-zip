package ee.forgr.plugin.capacitor_zip;

import java.net.URI;

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
                        return uriPath;
                    }
                }
            } catch (Exception ignored) {
                // fall through to return trimmed path below
            }
        }
        if (trimmed.contains("%")) {
            return decodePercentEncoded(trimmed);
        }
        return trimmed;
    }

    static String decodePercentEncoded(String path) {
        StringBuilder out = new StringBuilder(path.length());
        for (int i = 0; i < path.length(); i++) {
            char c = path.charAt(i);
            if (c == '%' && i + 2 < path.length()) {
                int hi = hexValue(path.charAt(i + 1));
                int lo = hexValue(path.charAt(i + 2));
                if (hi >= 0 && lo >= 0) {
                    out.append((char) ((hi << 4) + lo));
                    i += 2;
                    continue;
                }
            }
            out.append(c);
        }
        return out.toString();
    }

    private static int hexValue(char c) {
        if (c >= '0' && c <= '9') {
            return c - '0';
        }
        if (c >= 'a' && c <= 'f') {
            return c - 'a' + 10;
        }
        if (c >= 'A' && c <= 'F') {
            return c - 'A' + 10;
        }
        return -1;
    }
}
