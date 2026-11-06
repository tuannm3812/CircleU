import Foundation
import Security

/// What the Home Screen widget shows: a copy of one pocket card the person chose to put there.
/// Shared with the widget extension, so it depends on Foundation only.
nonisolated struct GuestPocketCardSnapshot: Codable, Equatable, Sendable {
    var wording: String
    var want: String?
    var steadyingLine: String
    /// The card's tone name: Soft, Balanced or Firm.
    var tone: String
    var made: Date
    /// The saved message it came from, so deleting that message takes the card off too.
    var messageID: UUID?
}

/// One card, in a place the app and the widget can both read. Nothing else from the journal goes
/// here: the widget never opens the journal store.
///
/// Guest Test keeps it in a shared keychain group because its signing profile has no App Groups.
/// Keychain items stay on this device and out of backups, but survive deleting the app, so
/// Delete all and "Take off Home Screen" are what remove it. Other builds embed no widget and use
/// a file in the app's own folder.
nonisolated struct GuestPocketCardShelf: Sendable {
    static let widgetKind = "CircleUPocketCard"
    /// Opened by tapping the widget.
    static let openURL = URL(string: "circleu-guest://pocket-card")!

    let read: @Sendable () -> Data?
    let write: @Sendable (Data) throws -> Void
    /// True when no card is left behind.
    let remove: @Sendable () -> Bool

    static var standard: GuestPocketCardShelf {
        #if GUEST_WIDGET_KEYCHAIN
        .keychain
        #else
        .file(at: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PocketCard.json"))
        #endif
    }

    func load() -> GuestPocketCardSnapshot? {
        read().flatMap { try? JSONDecoder().decode(GuestPocketCardSnapshot.self, from: $0) }
    }

    func save(_ card: GuestPocketCardSnapshot) throws {
        try write(JSONEncoder().encode(card))
    }

    static func file(at url: URL) -> GuestPocketCardShelf {
        GuestPocketCardShelf(
            read: { try? Data(contentsOf: url) },
            write: { data in
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: [.atomic, .completeFileProtection])
            },
            remove: {
                try? FileManager.default.removeItem(at: url)
                return !FileManager.default.fileExists(atPath: url.path)
            })
    }

    /// With no access group named, writes go to the first group in the entitlements, which is the
    /// one group the app and the widget share. Readable after the first unlock, so the widget can
    /// draw while the phone is locked; `privacySensitive` then hides the words on locked screens.
    static let keychain: GuestPocketCardShelf = {
        let item: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: "CircleU",
                                   kSecAttrAccount as String: "PocketCard"]
        return GuestPocketCardShelf(
            read: {
                var query = item
                query[kSecReturnData as String] = true
                var result: CFTypeRef?
                return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess ? result as? Data : nil
            },
            write: { data in
                SecItemDelete(item as CFDictionary)
                var add = item
                add[kSecValueData as String] = data
                add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                let status = SecItemAdd(add as CFDictionary, nil)
                guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
            },
            remove: {
                let status = SecItemDelete(item as CFDictionary)
                return status == errSecSuccess || status == errSecItemNotFound
            })
    }()
}
