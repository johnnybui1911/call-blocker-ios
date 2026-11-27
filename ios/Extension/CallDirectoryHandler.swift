import CallKit
import Foundation
import os
import BlockerCore

final class CallDirectoryHandler: CXCallDirectoryProvider {
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "call-directory", category: "blocking")

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        do {
            try provideNumbers(to: context)
            context.completeRequest()
        } catch {
            log.error("Call directory failed: \(error.localizedDescription, privacy: .public)")
            context.cancelRequest(withError: error)
        }
    }

    private func provideNumbers(to context: CXCallDirectoryExtensionContext) throws {
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }

        // No App Group means this process cannot see the host app's rules.
        // Publishing an empty list is the safe fallback: nothing is blocked,
        // and the host app explains why.
        guard SharedConfig.appGroupsBuildEnabled else {
            log.info("App Groups disabled at build time. Publishing an empty block list.")
            return
        }
        guard SharedConfig.isConfigured(SharedConfig.appGroupIdentifier) else {
            log.error("App Group identifier is missing from Info.plist.")
            return
        }
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedConfig.appGroupIdentifier
        ) else {
            log.error("App Group container is unavailable. Publishing an empty block list.")
            return
        }

        let url = container.appendingPathComponent(BlocklistFile.fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            log.info("No blocklist file yet.")
            return
        }

        var batch: [CXCallDirectoryPhoneNumber] = []
        batch.reserveCapacity(2_000)
        try BlocklistFile.forEachNumber(at: url) { number in
            batch.append(number)
            if batch.count == 2_000 {
                flush(&batch, to: context)
            }
        }
        if !batch.isEmpty {
            flush(&batch, to: context)
        }
    }

    private func flush(_ batch: inout [CXCallDirectoryPhoneNumber], to context: CXCallDirectoryExtensionContext) {
        let numbers = batch
        batch.removeAll(keepingCapacity: true)
        autoreleasepool {
            for number in numbers {
                context.addBlockingEntry(withNextSequentialPhoneNumber: number)
            }
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        log.error("requestFailed: \(error.localizedDescription, privacy: .public)")
    }
}
