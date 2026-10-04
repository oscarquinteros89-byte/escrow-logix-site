import Foundation
import Observation

enum AppTab: Hashable {
    case home, requests, contact, help
}

/// App-wide state: the selected tab, rep credit, saved requests and the open request sheet.
@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .home
    var attribution: Attribution
    let requests: RequestStore

    /// The Open Escrow sheet, when it's showing.
    var activeIntake: IntakeModel?
    /// Asks whether to resume the saved draft or start over.
    var showDraftChoice = false
    @ObservationIgnored private var pendingType: EscrowType?

    /// Where a tab should scroll next: "team" after tapping the rep card, or a demo screen's spot.
    var scrollAnchor: String?

    init() {
        #if DEBUG
        requests = RequestStore(inMemory: DemoMode.screen != nil)
        #else
        requests = RequestStore()
        #endif
        attribution = Attribution.current()
        #if DEBUG
        DemoMode.apply(to: self)
        #endif
    }

    /// Home buttons, Requests' empty state and rep links.
    func startIntake(_ type: EscrowType? = nil) {
        guard activeIntake == nil else { return }
        if requests.draft != nil {
            pendingType = type
            showDraftChoice = true
        } else {
            begin(type)
        }
    }

    /// "Start a new request" in the draft dialog.
    func startNewDiscardingDraft() {
        requests.discardDraft()
        begin(pendingType)
        pendingType = nil
    }

    func resumeDraft() {
        pendingType = nil
        guard let draft = requests.draft else { return }
        activeIntake = IntakeModel(form: draft.form, step: draft.step, attribution: attribution, store: requests)
    }

    private func begin(_ type: EscrowType?) {
        activeIntake = IntakeModel(form: IntakeForm(type: type), attribution: attribution, store: requests)
    }

    /// The rep card on Home: shows the team on the Contact tab.
    func showTeam() {
        selectedTab = .contact
        scrollAnchor = "team"
    }

    /// The sheet closed, by Done, the close button or a swipe.
    func intakeClosed(_ model: IntakeModel) {
        if !model.isFinished { model.saveDraftNow() }
    }

    /// escrowlogix:// links: rep credit, UTM tags, and optionally a type to start.
    func handle(_ url: URL) {
        let requested = attribution.apply(url)
        if let requested {
            selectedTab = .home
            startIntake(requested)
        }
    }
}
