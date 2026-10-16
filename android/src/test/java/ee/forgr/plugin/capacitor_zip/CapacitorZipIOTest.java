package ee.forgr.plugin.capacitor_zip;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class CapacitorZipIOTest {

    @Test
    public void bufferBytesMatchesUpdaterCryptoCipher() {
        assertEquals(256 * 1024, CapacitorZipIO.BUFFER_BYTES);
    }
}
