package ee.forgr.plugin.capacitor_zip;

import java.io.ByteArrayOutputStream;
import java.net.URI;
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
        if (path.length() >= 5 && path.regionMatches(true, 0, "file:", 0, 5)) {
            try {
                URI uri = new URI(path);
                if ("file".equalsIgnoreCase(uri.getScheme())) {
                    String uriPath = uri.getPath();
                    if (uriPath != null && !uriPath.isEmpty()) {
                        return uriPath;
                    }
                }
            } catch (Exception ignored) {
                return stripFileScheme(path);
            }
            return stripFileScheme(path);
        }
        if (!path.regionMatches(true, 0, "content:", 0, 8) && path.contains("%")) {
            return decodePercentEncoded(path);
        }
        return path;
    }

    static String stripFileScheme(String path) {
        String withoutScheme = path;
        if (withoutScheme.regionMatches(true, 0, "file://", 0, 7)) {
            withoutScheme = withoutScheme.substring(7);
        } else if (withoutScheme.regionMatches(true, 0, "file:", 0, 5)) {
            withoutScheme = withoutScheme.substring(5);
        }
        if (withoutScheme.startsWith("//")) {
            int pathStart = withoutScheme.indexOf('/', 2);
            withoutScheme = pathStart >= 0 ? withoutScheme.substring(pathStart) : "/";
        } else if (!withoutScheme.startsWith("/")) {
            int slash = withoutScheme.indexOf('/');
            if (slash > 0 && isFileUrlAuthority(withoutScheme.substring(0, slash))) {
                withoutScheme = withoutScheme.substring(slash);
            } else {
                withoutScheme = "/" + withoutScheme;
            }
        }
        if (withoutScheme.contains("%")) {
            return decodePercentEncoded(withoutScheme);
        }
        return withoutScheme;
    }

    static String decodePercentEncoded(String path) {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream(path.length());
        int i = 0;
        while (i < path.length()) {
            char c = path.charAt(i);
            if (c == '%' && i + 2 < path.length()) {
                int hi = hexValue(path.charAt(i + 1));
                int lo = hexValue(path.charAt(i + 2));
                if (hi >= 0 && lo >= 0) {
                    bytes.write((hi << 4) + lo);
                    i += 3;
                    continue;
                }
            }
            // Copy whole code points so surrogate pairs (non-BMP characters) stay intact.
            int codePoint = path.codePointAt(i);
            byte[] charBytes = new String(Character.toChars(codePoint)).getBytes(StandardCharsets.UTF_8);
            bytes.write(charBytes, 0, charBytes.length);
            i += Character.charCount(codePoint);
        }
        return new String(bytes.toByteArray(), StandardCharsets.UTF_8);
    }

    private static boolean isFileUrlAuthority(String segment) {
        if ("localhost".equalsIgnoreCase(segment)) {
            return true;
        }
        String[] octets = segment.split("\\.");
        if (octets.length != 4) {
            return false;
        }
        for (String octet : octets) {
            if (octet.isEmpty() || octet.length() > 3) {
                return false;
            }
            try {
                int value = Integer.parseInt(octet);
                if (value < 0 || value > 255) {
                    return false;
                }
            } catch (NumberFormatException e) {
                return false;
            }
        }
        return true;
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
