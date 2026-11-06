# R8 consumer rules for @capgo/capacitor-zip (consumed by app release minification in Capacitor 9+).

# Plugin entry and helpers: keep implementation so R8 does not remove code reachable only from the Capacitor bridge and zip4j paths.
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipPlugin { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipPlugin$* { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipErrorCode { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipIO { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipPath { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipProgress { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipProgress$* { *; }
-keep class ee.forgr.plugin.capacitor_zip.CapacitorZipProgressThrottle { *; }

# zip4j uses reflection for crypto providers and encryption engines; keep the library so password and AES paths stay working after minify.
-keep class net.lingala.zip4j.** { *; }
