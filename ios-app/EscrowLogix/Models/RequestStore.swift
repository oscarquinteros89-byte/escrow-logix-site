import Foundation
import Observation

/// A request that was sent, kept on this iPhone so the reference is always handy.
/// Only what the Requests tab shows is kept; documents are never stored.
struct SentRequest: Codable, Identifiable, Equatable {
    var id: String { reference }
    let reference: String
    let type: EscrowType
    let street: String
    let cityLine: String
    let sentAt: Date
    let documentStatus: DocumentStatus
    let senderName: String?
    /// Prototype mode: nothing actually reached Escrow Logix.
    let prototype: Bool
}

/// The request in progress, saved as the person types.
struct IntakeDraft: Codable, Equatable {
    var form: IntakeForm
    var step: Int
    var savedAt: Date
}

@MainActor
@Observable
final class RequestStore {
    private(set) var sent: [SentRequest] = []
    private(set) var draft: IntakeDraft?

    /// nil keeps everything in memory (demo screens and previews).
    private let fileURL: URL?

    private struct Snapshot: Codable {
        var sent: [SentRequest]
        var draft: IntakeDraft?
    }

    init(inMemory: Bool = false) {
        fileURL = inMemory ? nil : Self.storageURL()
        load()
    }

    func saveDraft(_ form: IntakeForm, step: Int) {
        draft = IntakeDraft(form: form, step: step, savedAt: .now)
        persist()
    }

    func discardDraft() {
        guard draft != nil else { return }
        draft = nil
        persist()
    }

    func record(_ request: SentRequest) {
        sent.removeAll { $0.reference == request.reference }
        sent.insert(request, at: 0)
        persist()
    }

    func remove(_ request: SentRequest) {
        sent.removeAll { $0.reference == request.reference }
        persist()
    }

    /// Demo data for screenshots.
    func replaceAll(sent: [SentRequest], draft: IntakeDraft?) {
        self.sent = sent
        self.draft = draft
        persist()
    }

    // MARK: Storage

    private static func storageURL() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("EscrowLogix", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("requests.json")
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        sent = snapshot.sent
        draft = snapshot.draft
    }

    private func persist() {
        guard let fileURL else { return }
        do {
            let data = try JSONEncoder().encode(Snapshot(sent: sent, draft: draft))
            // Encrypted while the iPhone is locked.
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            #if DEBUG
            print("RequestStore: couldn't save:", error)
            #endif
        }
    }
}
