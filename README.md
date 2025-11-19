# @capgo/capacitor-zip
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_zip"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_zip"> Missing a feature? We'll build the plugin for you 💪</a></h2>
</div>

A free Capacitor plugin for zipping and unzipping files on iOS, Android, and Web platforms.

## Why Capacitor Zip?

A **free and open-source alternative** for ZIP file operations in Capacitor apps:

- **Native Performance** - Uses platform-native ZIP libraries for fast compression
- **Password Protection** - AES encryption support on Android (iOS coming soon)
- **Cross-platform** - Works on iOS, Android, and Web
- **TypeScript** - Full TypeScript definitions included
- **Modern APIs** - Built with latest Capacitor 7 standards

Perfect for apps that need file compression, backup functionality, data export, or secure file transfers.

## Documentation

The most complete doc is available here: https://capgo.app/docs/plugins/zip/

## Install

```bash
npm install @capgo/capacitor-zip
npx cap sync
```

## API

<docgen-index>

* [`zip(...)`](#zip)
* [`unzip(...)`](#unzip)
* [`getPluginVersion()`](#getpluginversion)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Capacitor Zip Plugin for compressing and extracting zip archives.

Provides native ZIP file operations with platform-specific implementations:
- iOS: Uses ZIPFoundation (password protection not supported)
- Android: Uses zip4j with AES encryption support
- Web: Uses JSZip (unzip only, triggers downloads)

### zip(...)

```typescript
zip(options: ZipOptions) => Promise<void>
```

Compress a file or directory to create a ZIP archive.

Creates a compressed archive from a source file or directory. The archive
will include the entire directory structure if the source is a folder.

Platform-specific notes:
- iOS: Password protection is not supported. If a password is provided, it will be ignored and a warning will be logged.
- Android: Supports AES-256 encryption when a password is provided.
- Web: Not supported. Throws an error if called.

| Param         | Type                                              | Description                           |
| ------------- | ------------------------------------------------- | ------------------------------------- |
| **`options`** | <code><a href="#zipoptions">ZipOptions</a></code> | - Configuration for the zip operation |

**Since:** 7.0.0

--------------------


### unzip(...)

```typescript
unzip(options: UnzipOptions) => Promise<void>
```

Extract a ZIP archive to a specified destination directory.

Extracts all files and folders from a ZIP archive while preserving the
directory structure. Creates the destination directory if it doesn't exist.

Platform-specific notes:
- iOS: Supports standard ZIP archives. Password-protected archives are extracted with the provided password.
- Android: Supports AES-encrypted archives with password. Includes zip slip vulnerability protection.
- Web: Downloads each file individually to the browser's download folder. Cannot create a directory structure.

| Param         | Type                                                  | Description                             |
| ------------- | ----------------------------------------------------- | --------------------------------------- |
| **`options`** | <code><a href="#unzipoptions">UnzipOptions</a></code> | - Configuration for the unzip operation |

**Since:** 7.0.0

--------------------


### getPluginVersion()

```typescript
getPluginVersion() => Promise<{ version: string; }>
```

Get the native plugin version.

Returns the version of the native plugin code, which follows the Capacitor
major version (e.g., 7.0.0 for Capacitor 7.x).

**Returns:** <code>Promise&lt;{ version: string; }&gt;</code>

**Since:** 7.0.0

--------------------


### Interfaces


#### ZipOptions

Options for creating a ZIP archive.

| Prop              | Type                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Since |
| ----------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`source`**      | <code>string</code> | Path to the file or directory to compress. This can be an absolute path or a path relative to the app's working directory. If the source is a directory, all its contents will be recursively compressed while preserving the directory structure. Platform-specific notes: - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory. - Android: Use absolute file paths or content:// URIs for files accessible via the Android Storage Access Framework. - Web: Not supported. | 7.0.0 |
| **`destination`** | <code>string</code> | Path where the ZIP archive will be created. The destination path must include the .zip file extension. If the parent directory doesn't exist, it will be created automatically. Platform-specific notes: - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory. - Android: Use absolute file paths. The plugin will create any missing parent directories. - Web: Not supported.                                                                                              | 7.0.0 |
| **`password`**    | <code>string</code> | Optional password for encrypting the ZIP archive. When provided, the archive will be encrypted and require this password to extract. Uses AES-256 encryption on Android. Platform-specific notes: - iOS: Password protection is NOT supported. The password will be ignored and a warning will be logged. - Android: Supports AES-256 encryption via zip4j library. The password must be provided during extraction. - Web: Not supported.                                                                                        | 7.0.0 |


#### UnzipOptions

Options for extracting a ZIP archive.

| Prop              | Type                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Since |
| ----------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`source`**      | <code>string</code> | Path to the ZIP archive to extract. The source must be a valid ZIP file. If the file doesn't exist or is corrupted, the operation will fail with an error. Platform-specific notes: - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory. - Android: Use absolute file paths or content:// URIs for files accessible via the Android Storage Access Framework. - Web: Use HTTP/HTTPS URLs. The file will be fetched and extracted in the browser.                                          | 7.0.0 |
| **`destination`** | <code>string</code> | Path to the directory where files will be extracted. The destination directory will be created if it doesn't exist. All files and folders from the archive will be extracted while preserving the directory structure. Platform-specific notes: - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory. - Android: Use absolute file paths. Includes protection against zip slip vulnerabilities. - Web: Not applicable. Files are downloaded individually to the browser's download folder. | 7.0.0 |
| **`password`**    | <code>string</code> | Optional password for decrypting password-protected archives. Required if the ZIP archive was encrypted with a password. If the password is incorrect, extraction will fail with an error. Platform-specific notes: - iOS: Supports password-protected ZIP archives. - Android: Supports AES-encrypted archives created with zip4j or standard password-protected ZIPs. - Web: Not supported. Password-protected archives cannot be extracted in the browser.                                                                                   | 7.0.0 |

</docgen-api>

## Usage

### Basic Zip

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

// Zip a directory
await CapacitorZip.zip({
  source: '/path/to/directory',
  destination: '/path/to/output.zip'
});

// Zip a single file
await CapacitorZip.zip({
  source: '/path/to/file.txt',
  destination: '/path/to/output.zip'
});
```

### Zip with Password

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

await CapacitorZip.zip({
  source: '/path/to/directory',
  destination: '/path/to/output.zip',
  password: 'mySecurePassword123'
});
```

### Basic Unzip

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

await CapacitorZip.unzip({
  source: '/path/to/archive.zip',
  destination: '/path/to/extract'
});
```

### Unzip with Password

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

await CapacitorZip.unzip({
  source: '/path/to/encrypted.zip',
  destination: '/path/to/extract',
  password: 'mySecurePassword123'
});
```

### Get Plugin Version

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

const { version } = await CapacitorZip.getPluginVersion();
console.log('Plugin version:', version);
```

## Platform Support

| Platform | Supported | Password Protection | Notes |
|----------|-----------|---------------------|-------|
| iOS      | ✅        | ❌                  | Uses ZIPFoundation library (password not supported) |
| Android  | ✅        | ✅                  | Uses zip4j library for password-protected archives, standard Java ZIP for non-encrypted |
| Web      | ⚠️        | ❌                  | Limited support - unzip only triggers file downloads |

### Platform Limitations

#### iOS
- Password-protected archives are not supported with the current ZIPFoundation library
- If a password is provided, it will be ignored with a console warning

#### Android
- Full support for password-protected ZIP archives using AES encryption via zip4j

#### Web
The web implementation has the following limitations:
- **Zip**: Not supported (throws an error)
- **Unzip**: Triggers browser downloads for each file in the archive
- **Password**: Password-protected archives are not supported

For production web applications, consider using a server-side solution for zip operations.

## File Paths

### iOS
Use paths relative to the app's document directory or full paths:
```typescript
import { Filesystem, Directory } from '@capacitor/filesystem';

const { uri } = await Filesystem.getUri({
  directory: Directory.Documents,
  path: 'myfile.zip'
});

await CapacitorZip.unzip({
  source: uri,
  destination: Directory.Documents + '/extracted'
});
```

### Android
Use paths relative to the app's data directory or full paths:
```typescript
import { Filesystem, Directory } from '@capacitor/filesystem';

const { uri } = await Filesystem.getUri({
  directory: Directory.Data,
  path: 'myfile.zip'
});

await CapacitorZip.unzip({
  source: uri,
  destination: Directory.Data + '/extracted'
});
```

## Error Handling

```typescript
import { CapacitorZip } from '@capgo/capacitor-zip';

try {
  await CapacitorZip.zip({
    source: '/path/to/directory',
    destination: '/path/to/output.zip'
  });
  console.log('Zip created successfully!');
} catch (error) {
  console.error('Failed to create zip:', error);
}
```

## Dependencies

### iOS
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) - Provides ZIP compression with AES encryption

### Android
- [zip4j](https://github.com/srikanth-lingala/zip4j) - Provides password-protected ZIP support

### Web
- [JSZip](https://stuk.github.io/jszip/) - JavaScript ZIP library (limited functionality)

## License

MIT

## Credits

Created by Martin Donadieu for [Capgo](https://capgo.app)
