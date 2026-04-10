import Foundation

public final class ConfigurationStore {
    public let fileURL: URL
    private let fileManager: FileManager

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultConfigurationURL(fileManager: fileManager)
    }

    public func load() throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return AppConfiguration()
        }

        let data = try Data(contentsOf: fileURL)
        var configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
        configuration.normalizeActiveAccount()
        return configuration
    }

    public func save(_ configuration: AppConfiguration) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        var normalized = configuration
        normalized.normalizeActiveAccount()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(normalized)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func defaultConfigurationURL(fileManager: FileManager) -> URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directoryURL = appSupportURL.appendingPathComponent("CodingBalanceDisplayMac", isDirectory: true)
        return directoryURL.appendingPathComponent("config.json")
    }
}
