import Foundation

public enum BlocklistFileError: Error, Equatable {
    case exceedsHardCap
    case badMagic
    case unsupportedVersion
    case truncated
    case notStrictlyAscending
    case unreadableNumber
}

/// Compact little-endian blocklist.
///
/// ```
/// 0  magic        4 bytes  "CBLK"
/// 4  version      UInt16   1
/// 6  reserved     UInt16   0
/// 8  count        UInt64
/// 16 numbers      Int64 × count, strictly ascending, unique
/// ```
public enum BlocklistFile {
    public static let fileName = "blocklist.bin"
    public static let magic = Data("CBLK".utf8)
    public static let version: UInt16 = 1
    public static let headerLength = 16

    public static func write(ranges: [NumberRange], to url: URL) throws {
        var count: UInt64 = 0
        for range in ranges {
            let (sum, overflow) = count.addingReportingOverflow(range.count)
            if overflow || sum > Limits.hardCap {
                throw BlocklistFileError.exceedsHardCap
            }
            count = sum
        }

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(url.lastPathComponent + ".tmp")
        if FileManager.default.fileExists(atPath: temporary.path) {
            try FileManager.default.removeItem(at: temporary)
        }
        _ = FileManager.default.createFile(atPath: temporary.path, contents: nil)
        let handle = try FileHandle(forWritingTo: temporary)
        do {
            try handle.write(contentsOf: header(count: count))
            var previous: UInt64?
            var buffer = Data()
            buffer.reserveCapacity(8 * 1024)
            for range in ranges {
                var value = range.lower
                while true {
                    if let previous, value <= previous {
                        throw BlocklistFileError.notStrictlyAscending
                    }
                    previous = value
                    appendLE(Int64(value), to: &buffer)
                    if buffer.count >= 8 * 1024 {
                        try handle.write(contentsOf: buffer)
                        buffer.removeAll(keepingCapacity: true)
                    }
                    if value == range.upper { break }
                    value += 1
                }
            }
            if !buffer.isEmpty {
                try handle.write(contentsOf: buffer)
            }
            try handle.close()
        } catch {
            try? handle.close()
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }

        try replace(temporary: temporary, final: url)
    }

    public static func forEachNumber(at url: URL, _ body: (Int64) throws -> Void) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        guard let headerData = try handle.read(upToCount: headerLength), headerData.count == headerLength else {
            throw BlocklistFileError.truncated
        }
        guard headerData.prefix(4) == magic else {
            throw BlocklistFileError.badMagic
        }
        let fileVersion: UInt16 = readLE(headerData, offset: 4)
        guard fileVersion == version else {
            throw BlocklistFileError.unsupportedVersion
        }
        let count: UInt64 = readLE(headerData, offset: 8)

        var remaining = count
        var previous: Int64?
        let chunkCount = 4096
        while remaining > 0 {
            let take = remaining > UInt64(chunkCount) ? chunkCount : Int(remaining)
            guard let chunk = try handle.read(upToCount: take * 8), chunk.count == take * 8 else {
                throw BlocklistFileError.truncated
            }
            var offset = 0
            for _ in 0..<take {
                let number: Int64 = readLE(chunk, offset: offset)
                offset += 8
                if number < 0 {
                    throw BlocklistFileError.unreadableNumber
                }
                if let previous, number <= previous {
                    throw BlocklistFileError.notStrictlyAscending
                }
                previous = number
                try body(number)
            }
            remaining -= UInt64(take)
        }
    }

    private static func header(count: UInt64) -> Data {
        var data = Data()
        data.reserveCapacity(headerLength)
        data.append(magic)
        appendLE(version, to: &data)
        appendLE(UInt16(0), to: &data)
        appendLE(count, to: &data)
        return data
    }

    private static func replace(temporary: URL, final: URL) throws {
        #if canImport(Darwin)
        if FileManager.default.fileExists(atPath: final.path) {
            _ = try FileManager.default.replaceItemAt(final, withItemAt: temporary)
            return
        }
        #endif
        if FileManager.default.fileExists(atPath: final.path) {
            try FileManager.default.removeItem(at: final)
        }
        try FileManager.default.moveItem(at: temporary, to: final)
    }
}

func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
}

func readLE<T: FixedWidthInteger>(_ data: Data, offset: Int) -> T {
    let end = offset + MemoryLayout<T>.size
    precondition(offset >= 0 && end <= data.count)
    var value: T = 0
    _ = withUnsafeMutableBytes(of: &value) { destination in
        data.copyBytes(to: destination, from: offset..<end)
    }
    return T(littleEndian: value)
}
