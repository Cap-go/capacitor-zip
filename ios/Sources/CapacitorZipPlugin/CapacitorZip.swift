import Foundation
import ZIPFoundation

public class CapacitorZip: NSObject {

    /**
     * Creates a zip archive from a source file or directory
     * Note: Password protection is not supported on iOS with ZIPFoundation
     */
    public func zip(source: String, destination: String, password: String? = nil, includeParentFolder: Bool = true) throws {
        let sourceURL = URL(fileURLWithPath: source)
        let destinationURL = URL(fileURLWithPath: destination)

        // Check if source exists
        guard FileManager.default.fileExists(atPath: source) else {
            throw NSError(domain: "CapacitorZip", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source path does not exist"])
        }

        // Warn if password is provided (not supported)
        if password != nil && !password!.isEmpty {
            print("Warning: Password protection is not supported on iOS")
        }

        // Create parent directory if it doesn't exist
        let parentDir = destinationURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
        }

        // Remove existing destination file if it exists
        if FileManager.default.fileExists(atPath: destination) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // Check if source is a directory
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: source, isDirectory: &isDirectory)
        
        if isDirectory.boolValue && !includeParentFolder {
            // Zip only the contents of the directory without the parent folder
            try zipDirectoryContents(at: sourceURL, to: destinationURL)
        } else {
            // Zip the item (file or directory) normally
            try FileManager.default.zipItem(at: sourceURL, to: destinationURL)
        }
    }
    
    /**
     * Zips only the contents of a directory without including the parent folder
     */
    private func zipDirectoryContents(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Get all items in the source directory
        let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)
        
        // Create the archive
        guard let archive = Archive(url: destinationURL, accessMode: .create) else {
            throw NSError(domain: "CapacitorZip", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create archive"])
        }
        
        // Add each item to the archive
        for itemURL in contents {
            try addItemToArchive(itemURL: itemURL, archive: archive, basePath: "")
        }
    }
    
    /**
     * Recursively adds an item to the archive
     */
    private func addItemToArchive(itemURL: URL, archive: Archive, basePath: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory)
        
        let itemName = itemURL.lastPathComponent
        let archivePath = basePath.isEmpty ? itemName : "\(basePath)/\(itemName)"
        
        if isDirectory.boolValue {
            // Add directory recursively
            let contents = try fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: nil)
            for subItemURL in contents {
                try addItemToArchive(itemURL: subItemURL, archive: archive, basePath: archivePath)
            }
        } else {
            // Add file using FileManager extension
            try archive.addEntry(with: archivePath, relativeTo: itemURL.deletingLastPathComponent())
        }
    }

    /**
     * Extracts a zip archive to a destination directory
     * Note: Password protection is not supported on iOS with ZIPFoundation
     */
    public func unzip(source: String, destination: String, password: String? = nil) throws {
        let sourceURL = URL(fileURLWithPath: source)
        let destinationURL = URL(fileURLWithPath: destination)

        // Check if source exists
        guard FileManager.default.fileExists(atPath: source) else {
            throw NSError(domain: "CapacitorZip", code: 2, userInfo: [NSLocalizedDescriptionKey: "Source zip file does not exist"])
        }

        // Warn if password is provided (not supported)
        if password != nil && !password!.isEmpty {
            print("Warning: Password protection is not supported on iOS")
        }

        // Create destination directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: destination) {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }

        // Unzip the item
        try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
    }
}
