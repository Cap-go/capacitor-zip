package ee.forgr.plugin.capacitor_zip;

/** Stable error codes surfaced to JavaScript via plugin rejections (messages stay unchanged). */
public final class CapacitorZipErrorCode {

    public static final String SOURCE_REQUIRED = "ZIP_SOURCE_REQUIRED";
    public static final String DESTINATION_REQUIRED = "ZIP_DESTINATION_REQUIRED";
    public static final String ZIP_FAILED = "ZIP_FAILED";
    public static final String UNZIP_FAILED = "ZIP_UNZIP_FAILED";

    private CapacitorZipErrorCode() {}
}
