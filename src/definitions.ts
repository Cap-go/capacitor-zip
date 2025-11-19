/**
 * Capacitor Zip Plugin for compressing and extracting zip archives.
 *
 * Provides native ZIP file operations with platform-specific implementations:
 * - iOS: Uses ZIPFoundation (password protection not supported)
 * - Android: Uses zip4j with AES encryption support
 * - Web: Uses JSZip (unzip only, triggers downloads)
 *
 * @since 7.0.0
 */
export interface CapacitorZipPlugin {
  /**
   * Compress a file or directory to create a ZIP archive.
   *
   * Creates a compressed archive from a source file or directory. The archive
   * will include the entire directory structure if the source is a folder.
   *
   * Platform-specific notes:
   * - iOS: Password protection is not supported. If a password is provided, it will be ignored and a warning will be logged.
   * - Android: Supports AES-256 encryption when a password is provided.
   * - Web: Not supported. Throws an error if called.
   *
   * @param options - Configuration for the zip operation
   * @returns Promise that resolves when the archive is created successfully
   * @throws Error if the source path doesn't exist, destination cannot be created, or compression fails
   * @since 7.0.0
   * @example
   * ```typescript
   * // Compress a directory without password
   * await CapacitorZip.zip({
   *   source: '/path/to/my-folder',
   *   destination: '/path/to/output.zip'
   * });
   * ```
   * @example
   * ```typescript
   * // Compress a file with password (Android only)
   * await CapacitorZip.zip({
   *   source: '/path/to/document.pdf',
   *   destination: '/path/to/protected.zip',
   *   password: 'mySecurePassword123'
   * });
   * ```
   */
  zip(options: ZipOptions): Promise<void>;

  /**
   * Extract a ZIP archive to a specified destination directory.
   *
   * Extracts all files and folders from a ZIP archive while preserving the
   * directory structure. Creates the destination directory if it doesn't exist.
   *
   * Platform-specific notes:
   * - iOS: Supports standard ZIP archives. Password-protected archives are extracted with the provided password.
   * - Android: Supports AES-encrypted archives with password. Includes zip slip vulnerability protection.
   * - Web: Downloads each file individually to the browser's download folder. Cannot create a directory structure.
   *
   * @param options - Configuration for the unzip operation
   * @returns Promise that resolves when extraction is complete
   * @throws Error if the source file doesn't exist, is not a valid ZIP archive, password is incorrect, or extraction fails
   * @since 7.0.0
   * @example
   * ```typescript
   * // Extract a standard ZIP archive
   * await CapacitorZip.unzip({
   *   source: '/path/to/archive.zip',
   *   destination: '/path/to/extract-folder'
   * });
   * ```
   * @example
   * ```typescript
   * // Extract a password-protected archive
   * await CapacitorZip.unzip({
   *   source: '/path/to/protected.zip',
   *   destination: '/path/to/extract-folder',
   *   password: 'mySecurePassword123'
   * });
   * ```
   */
  unzip(options: UnzipOptions): Promise<void>;

  /**
   * Get the native plugin version.
   *
   * Returns the version of the native plugin code, which follows the Capacitor
   * major version (e.g., 7.0.0 for Capacitor 7.x).
   *
   * @returns Promise that resolves with an object containing the version string
   * @throws Error if unable to retrieve the version
   * @since 7.0.0
   * @example
   * ```typescript
   * const { version } = await CapacitorZip.getPluginVersion();
   * console.log('Plugin version:', version); // "7.0.0"
   * ```
   */
  getPluginVersion(): Promise<{ version: string }>;
}

/**
 * Options for creating a ZIP archive.
 *
 * @since 7.0.0
 */
export interface ZipOptions {
  /**
   * Path to the file or directory to compress.
   *
   * This can be an absolute path or a path relative to the app's working directory.
   * If the source is a directory, all its contents will be recursively compressed
   * while preserving the directory structure.
   *
   * Platform-specific notes:
   * - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory.
   * - Android: Use absolute file paths or content:// URIs for files accessible via the Android Storage Access Framework.
   * - Web: Not supported.
   *
   * @since 7.0.0
   * @example '/Users/app/Documents/my-folder'
   * @example '/var/mobile/Containers/Data/Application/.../Documents/file.pdf'
   * @example 'file:///storage/emulated/0/Download/document.pdf'
   */
  source: string;

  /**
   * Path where the ZIP archive will be created.
   *
   * The destination path must include the .zip file extension. If the parent
   * directory doesn't exist, it will be created automatically.
   *
   * Platform-specific notes:
   * - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory.
   * - Android: Use absolute file paths. The plugin will create any missing parent directories.
   * - Web: Not supported.
   *
   * @since 7.0.0
   * @example '/Users/app/Documents/archive.zip'
   * @example '/var/mobile/Containers/Data/Application/.../Documents/backup.zip'
   * @example 'file:///storage/emulated/0/Download/compressed.zip'
   */
  destination: string;

  /**
   * Optional password for encrypting the ZIP archive.
   *
   * When provided, the archive will be encrypted and require this password
   * to extract. Uses AES-256 encryption on Android.
   *
   * Platform-specific notes:
   * - iOS: Password protection is NOT supported. The password will be ignored and a warning will be logged.
   * - Android: Supports AES-256 encryption via zip4j library. The password must be provided during extraction.
   * - Web: Not supported.
   *
   * @since 7.0.0
   * @example 'mySecurePassword123'
   */
  password?: string;
}

/**
 * Options for extracting a ZIP archive.
 *
 * @since 7.0.0
 */
export interface UnzipOptions {
  /**
   * Path to the ZIP archive to extract.
   *
   * The source must be a valid ZIP file. If the file doesn't exist or is
   * corrupted, the operation will fail with an error.
   *
   * Platform-specific notes:
   * - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory.
   * - Android: Use absolute file paths or content:// URIs for files accessible via the Android Storage Access Framework.
   * - Web: Use HTTP/HTTPS URLs. The file will be fetched and extracted in the browser.
   *
   * @since 7.0.0
   * @example '/Users/app/Documents/archive.zip'
   * @example '/var/mobile/Containers/Data/Application/.../Documents/backup.zip'
   * @example 'file:///storage/emulated/0/Download/compressed.zip'
   * @example 'https://example.com/files/archive.zip' (Web only)
   */
  source: string;

  /**
   * Path to the directory where files will be extracted.
   *
   * The destination directory will be created if it doesn't exist. All files
   * and folders from the archive will be extracted while preserving the
   * directory structure.
   *
   * Platform-specific notes:
   * - iOS: Use file:// URLs or absolute paths. Relative paths are resolved from the app's documents directory.
   * - Android: Use absolute file paths. Includes protection against zip slip vulnerabilities.
   * - Web: Not applicable. Files are downloaded individually to the browser's download folder.
   *
   * @since 7.0.0
   * @example '/Users/app/Documents/extracted'
   * @example '/var/mobile/Containers/Data/Application/.../Documents/files'
   * @example 'file:///storage/emulated/0/Download/extracted-files'
   */
  destination: string;

  /**
   * Optional password for decrypting password-protected archives.
   *
   * Required if the ZIP archive was encrypted with a password. If the password
   * is incorrect, extraction will fail with an error.
   *
   * Platform-specific notes:
   * - iOS: Supports password-protected ZIP archives.
   * - Android: Supports AES-encrypted archives created with zip4j or standard password-protected ZIPs.
   * - Web: Not supported. Password-protected archives cannot be extracted in the browser.
   *
   * @since 7.0.0
   * @example 'mySecurePassword123'
   */
  password?: string;
}
