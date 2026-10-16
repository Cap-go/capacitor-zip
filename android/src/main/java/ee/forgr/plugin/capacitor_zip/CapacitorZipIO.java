package ee.forgr.plugin.capacitor_zip;

/**
 * I/O buffer sizing aligned with Cap-go/capacitor-updater {@code CryptoCipher.ioBufferBytes()}.
 */
public final class CapacitorZipIO {

    public static final int BUFFER_BYTES = 256 * 1024;

    private CapacitorZipIO() {}
}
