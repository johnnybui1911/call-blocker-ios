import Foundation

public enum RuleArchive {
    public static let fileName = "rules.json"

    public static func loadIfPresent(from url: URL) throws -> [BlockRule] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        if data.isEmpty {
            return []
        }
        return try JSONDecoder().decode([BlockRule].self, from: data)
    }

    public static func save(_ rules: [BlockRule], to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(rules)
        try data.write(to: url, options: .atomic)
    }
}
