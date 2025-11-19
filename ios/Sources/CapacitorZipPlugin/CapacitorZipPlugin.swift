import Foundation
import Capacitor

/**
 * Capacitor Zip Plugin for iOS
 * Provides zip and unzip functionality with optional password protection
 */
@objc(CapacitorZipPlugin)
public class CapacitorZipPlugin: CAPPlugin, CAPBridgedPlugin {
    private let pluginVersion: String = "7.0.1"
    public let identifier = "CapacitorZipPlugin"
    public let jsName = "CapacitorZip"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "zip", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "unzip", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = CapacitorZip()

    @objc func zip(_ call: CAPPluginCall) {
        guard let source = call.getString("source") else {
            call.reject("Source path is required")
            return
        }

        guard let destination = call.getString("destination") else {
            call.reject("Destination path is required")
            return
        }

        let password = call.getString("password")

        do {
            try implementation.zip(source: source, destination: destination, password: password)
            call.resolve()
        } catch {
            call.reject("Failed to create zip archive: \(error.localizedDescription)")
        }
    }

    @objc func unzip(_ call: CAPPluginCall) {
        guard let source = call.getString("source") else {
            call.reject("Source path is required")
            return
        }

        guard let destination = call.getString("destination") else {
            call.reject("Destination path is required")
            return
        }

        let password = call.getString("password")

        do {
            try implementation.unzip(source: source, destination: destination, password: password)
            call.resolve()
        } catch {
            call.reject("Failed to extract zip archive: \(error.localizedDescription)")
        }
    }

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve(["version": self.pluginVersion])
    }
}
