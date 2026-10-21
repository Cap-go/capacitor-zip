import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Progress payload emitted on the `progress` listener during `zip` and `unzip`.
 *
 * @since 8.2.0
 */
export interface ZipProgressEvent {
  /**
   * Unique id for the `zip` or `unzip` call that produced this event.
   *
   * Use this to distinguish concurrent operations when using `addListener`.
   *
   * @since 8.3.0
   */
  operationId: string;
  /**
   * `source` path from the `zip` or `unzip` options for this operation.
   *
   * @since 8.3.0
   */
  source: string;
  /**
   * `destination` path from the `zip` or `unzip` options for this operation.
   *
   * @since 8.3.0
   */
  destination: string;
  /**
   * Whether bytes are being compressed or extracted.
   */
  operation: 'zip' | 'unzip';
  /**
   * Bytes processed so far (uncompressed size when known).
   *
   * Same meaning as `ProgressEvent.loaded` in the Web platform.
   */
  loaded: number;
  /**
   * Total bytes for the operation when known, otherwise `0`.
   *
   * Same meaning as `ProgressEvent.total` in the Web platform.
   */
  total: number;
  /**
   * Whether `total` (or file totals) represent a known length for this operation.
   *
   * Aligns with `ProgressEvent.lengthComputable`.
   */
  lengthComputable: boolean;
  /**
   * Ratio from `0` to `1` based on bytes when `total > 0`, otherwise file counts when available.
   */
  progress: number;
  /**
   * Path or name of the entry currently being processed.
   */
  currentFile?: string;
  /**
   * Number of archive entries completed so far.
   */
  filesCompleted?: number;
  /**
   * Total entries in the archive when known.
   */
  filesTotal?: number;
}

/**
 * Capacitor Zip Plugin for compressing and extracting zip archives.
 *
 * Provides native ZIP file operations with platform-specific implementations:
 * - iOS: Uses ZIPFoundation (password protection not supported)
 * - Android: Uses zip4j with AES encryption support
 * - Web: Uses zip.js (unzip only, triggers downloads)
 *
 * @since 7.0.0
 */
export interface CapacitorZipPlugin {
  /**
   * Listen for progress updates while `zip` or `unzip` is running.
   *
   * Register before starting the operation. Events are best-effort on web (unzip only).
   * Each event includes `operationId`, `source`, and `destination` so you can filter when several operations run at once.
   *
   * @param eventName The event name (`progress`).
   * @param listenerFunc Called with `ZipProgressEvent` payloads (includes `loaded`, `total`, and `lengthComputable` like `ProgressEvent`).
   * @since 8.2.0
   * @example
   * ```typescript
   * const handle = await CapacitorZip.addListener('progress', (event) => {
   *   console.log(`${event.operation} ${Math.round(event.progress * 100)}%`, event.currentFile);
   * });
   * try {
   *   await CapacitorZip.unzip({ source, destination });
   * } finally {
   *   await handle.remove();
   * }
   * ```
   */
  addListener(eventName: 'progress', listenerFunc: (event: ZipProgressEvent) => void): Promise<PluginListenerHandle>;

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
   * - iOS: Supports standard ZIP archives. Password-protected archives are not supported; a provided password is ignored.
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
   * On iOS and Android, `file://` URLs (for example from Cordova `FileEntry.nativeURL`) and
   * percent-encoded path segments are normalized to filesystem paths before zip/unzip runs.
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
   * On iOS and Android, `file://` URLs and percent-encoded path segments are normalized to
   * filesystem paths before zip runs.
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

  /**
   * Whether to include the parent folder in the ZIP archive.
   *
   * When true (default), the source folder itself becomes the root directory in the archive.
   * When false, only the contents of the source folder are included at the root level.
   *
   * This option only applies when the source is a directory. For single files, this option is ignored.
   *
   * @default true
   * @since 8.0.5
   * @example
   * ```typescript
   * // With includeParentFolder: true (default)
   * // Source: /cache/temp/ containing [database.backup, media/]
   * // ZIP contains: temp/database.backup, temp/media/
   * await CapacitorZip.zip({
   *   source: '/cache/temp',
   *   destination: '/cache/backup.zip',
   *   includeParentFolder: true
   * });
   * ```
   * @example
   * ```typescript
   * // With includeParentFolder: false
   * // Source: /cache/temp/ containing [database.backup, media/]
   * // ZIP contains: database.backup, media/
   * await CapacitorZip.zip({
   *   source: '/cache/temp',
   *   destination: '/cache/backup.zip',
   *   includeParentFolder: false
   * });
   * ```
   */
  includeParentFolder?: boolean;

  /**
   * Called with progress updates for this zip operation only.
   *
   * Prefer this over `addListener('progress')` when running multiple operations at once.
   * The listener is registered and removed automatically.
   *
   * @since 8.3.0
   */
  onProgress?: (event: ZipProgressEvent) => void;

  /**
   * Optional operation id (generated automatically when omitted).
   *
   * @since 8.3.0
   */
  operationId?: string;
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
   * On iOS and Android, `file://` URLs (for example from Cordova `FileEntry.nativeURL`) and
   * percent-encoded path segments are normalized to filesystem paths before unzip runs.
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
   * On iOS and Android, `file://` URLs and percent-encoded path segments are normalized to
   * filesystem paths before unzip runs.
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
   * - iOS: Password-protected ZIP archives are not supported. If a password is provided, it is ignored and a warning is logged.
   * - Android: Supports AES-encrypted archives created with zip4j or standard password-protected ZIPs.
   * - Web: Not supported. Password-protected archives cannot be extracted in the browser.
   *
   * @since 7.0.0
   * @example 'mySecurePassword123'
   */
  password?: string;

  /**
   * Called with progress updates for this unzip operation only.
   *
   * Prefer this over `addListener('progress')` when running multiple operations at once.
   * The listener is registered and removed automatically.
   *
   * @since 8.3.0
   */
  onProgress?: (event: ZipProgressEvent) => void;

  /**
   * Optional operation id (generated automatically when omitted).
   *
   * @since 8.3.0
   */
  operationId?: string;
}
