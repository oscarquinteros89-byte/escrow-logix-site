import Foundation
import Observation

/// One Open Escrow request, from step 1 to the success screen.
@MainActor
@Observable
final class IntakeModel: Identifiable {
    let id = UUID()

    var form: IntakeForm

    /// 1 to 5 are the form steps, 6 is the success screen.
    private(set) var step: Int
    /// Which way the last step change went, for the slide direction.
    private(set) var movingForward = true
    private(set) var isSubmitting = false
    var submitError: String?
    /// The JSON that would go to the CRM, shown in prototype mode.
    private(set) var payloadPreview: String?
    /// Asks the view to focus and scroll to a field.
    private(set) var focusRequest: FocusRequest?
    /// Bumps on every blocked Continue, for the error haptic.
    private(set) var errorCount = 0

    /// Steps where Continue was tapped; their errors show and update live.
    private var attempted: Set<Int> = []

    let attribution: Attribution
    private let store: RequestStore
    @ObservationIgnored private var reportedSteps: Set<Int> = []
    @ObservationIgnored private var autosaveTask: Task<Void, Never>?

    /// Debug-only demo screens: a field to scroll to once the sheet is open.
    var demoScroll: DemoScroll?

    struct DemoScroll {
        let field: Field
        var atBottom = true
        var focuses = false
    }

    /// False after "Delete it", so closing the sheet doesn't save it again.
    @ObservationIgnored private var keepsDraft = true

    struct FocusRequest: Equatable {
        let field: Field
        let id = UUID()
    }

    static let stepNames = ["Transaction type", "Contact", "Transaction details", "Documents", "Review", "Submitted"]
    static let shortStepNames = ["Type", "Contact", "Transaction", "Documents", "Review"]

    init(form: IntakeForm = IntakeForm(), step: Int = 1, attribution: Attribution, store: RequestStore) {
        self.form = form
        self.step = min(max(step, 1), 5)
        self.attribution = attribution
        self.store = store
        if self.step >= 4 { ensureReference() }
    }

    var type: EscrowType { form.type ?? .purchase }
    var reference: String { form.reference ?? "" }
    var isFinished: Bool { step == 6 }
    var hasContent: Bool { form.hasContent }
    var shareFileURL: URL? { AppConfig.shareFile[type] }

    var subtitle: String {
        isFinished ? "Request sent" : "Step \(step) of 5 · \(Self.shortStepNames[step - 1])"
    }

    var primaryTitle: String {
        switch step {
        case 4: return "Continue to review"
        case 5: return isSubmitting ? "Submitting…" : "Submit escrow request"
        case 6: return "Done"
        default: return "Continue"
        }
    }

    var canContinue: Bool { step != 1 || form.type != nil }

    // MARK: Errors

    func error(_ field: Field) -> String? {
        guard attempted.contains(Validator.step(of: field)) else { return nil }
        return Validator.message(for: field, in: form)
    }

    // MARK: Navigation

    func choose(_ type: EscrowType) {
        form.type = type
    }

    /// The bottom button on steps 1 to 4.
    func advance() {
        switch step {
        case 1:
            guard form.type != nil else { return }
            move(to: 2)
        case 2...4:
            attempted.insert(step)
            if let field = Validator.firstInvalid(onStep: step, in: form) {
                errorCount += 1
                focusRequest = FocusRequest(field: field)
                return
            }
            move(to: step + 1)
        default:
            break
        }
    }

    func back() {
        guard (2...5).contains(step) else { return }
        move(to: step - 1)
    }

    /// "Edit" links on the review step.
    func edit(step target: Int) {
        move(to: target)
    }

    private func move(to target: Int) {
        movingForward = target > step
        step = target
        if target == 4 { ensureReference() }
        reportStep(target)
        scheduleAutosave()
    }

    /// Created when the Documents step opens, and kept if the person goes back.
    func ensureReference() {
        if form.reference == nil { form.reference = Reference.make() }
    }

    // MARK: Field clean-up

    /// Tidies a field when focus leaves it, as the website does on blur.
    func didLeave(_ field: Field?) {
        switch field {
        case .phone: form.phone = Format.phone(form.phone)
        case .salePrice: form.salePrice = Format.money(form.salePrice)
        case .deposit: form.deposit = Format.money(form.deposit)
        case .loanAmount: form.loanAmount = Format.money(form.loanAmount)
        case .state: form.state = String(form.state.trimmed.uppercased().prefix(2))
        case .email: form.email = form.email.trimmed
        case .senderEmail: form.senderEmail = form.senderEmail.trimmed
        default: break
        }
    }

    // MARK: Submit

    func submit() async {
        guard !isSubmitting else { return }
        submitError = nil
        attempted.insert(5)
        guard form.consent else {
            errorCount += 1
            focusRequest = FocusRequest(field: .consent)
            return
        }
        ensureReference()
        let payload = PayloadBuilder.payload(form: form, attribution: attribution, submittedAt: .now)

        if let endpoint = AppConfig.crmEndpoint {
            isSubmitting = true
            do {
                try await CRMClient.send(payload, to: endpoint)
                isSubmitting = false
                Analytics.track(.generateLead, [
                    "escrow_type": type.rawValue,
                    "document_status": form.documentStatus?.rawValue ?? "",
                    "contact_role": form.role,
                    "rep": attribution.repName ?? ""
                ])
            } catch {
                isSubmitting = false
                Analytics.track(.escrowSubmitFailed, [
                    "escrow_type": type.rawValue,
                    "error_detail": error.localizedDescription,
                    "rep": attribution.repName ?? ""
                ])
                submitError = "We couldn't send your request. Please try again, or call \(Office.phoneDisplay) and mention reference \(reference)."
                errorCount += 1
                return
            }
        } else {
            payloadPreview = payload.rendered(pretty: true)
        }

        autosaveTask?.cancel()
        store.record(SentRequest(
            reference: reference,
            type: type,
            street: form.street.trimmed,
            cityLine: form.cityLine,
            sentAt: .now,
            documentStatus: form.documentStatus ?? .sendingLater,
            senderName: form.documentStatus == .agentOrLenderWillSend && !form.senderName.isBlank ? form.senderName.trimmed : nil,
            prototype: AppConfig.isPrototype
        ))
        store.discardDraft()
        move(to: 6)
    }

    /// "Open another escrow" on the success screen.
    func startOver() {
        autosaveTask?.cancel()
        keepsDraft = true
        form = IntakeForm()
        attempted = []
        reportedSteps = []
        payloadPreview = nil
        submitError = nil
        focusRequest = nil
        movingForward = false
        step = 1
    }

    // MARK: Drafts

    /// The sheet calls this whenever the form changes.
    func formDidChange() {
        scheduleAutosave()
    }

    private func scheduleAutosave() {
        guard keepsDraft, step <= 5 else { return }
        autosaveTask?.cancel()
        let snapshot = form
        let currentStep = step
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, let self else { return }
            if snapshot.hasContent { self.store.saveDraft(snapshot, step: currentStep) }
        }
    }

    /// Called when the sheet closes without submitting.
    func saveDraftNow() {
        autosaveTask?.cancel()
        guard keepsDraft, step <= 5 else { return }
        if form.hasContent { store.saveDraft(form, step: step) } else { store.discardDraft() }
    }

    /// "Delete it" in the close dialog.
    func discardDraft() {
        keepsDraft = false
        autosaveTask?.cancel()
        store.discardDraft()
    }

    // MARK: Analytics

    /// escrow_step for steps 2 to 5, once each per request (same rule as the website).
    private func reportStep(_ number: Int) {
        guard (2...5).contains(number), !reportedSteps.contains(number) else { return }
        reportedSteps.insert(number)
        Analytics.track(.escrowStep, [
            "step_number": String(number),
            "step_name": Self.stepNames[number - 1],
            "escrow_type": type.rawValue,
            "rep": attribution.repName ?? ""
        ])
    }

    // MARK: Review

    struct ReviewRow: Identifiable {
        let key: String
        let value: String
        var id: String { key }
    }

    struct ReviewSection: Identifiable {
        let title: String
        let step: Int
        let rows: [ReviewRow]
        var id: Int { step }
    }

    /// Same groups and labels as the website's review step; empty answers are left out.
    var reviewSections: [ReviewSection] {
        let isPurchase = type == .purchase
        var transaction: [(String, String)] = [("Type", type.title)]
        if let rep = attribution.rep {
            transaction.append(("Escrow Logix contact", rep.name + (rep.title.map { ", \($0)" } ?? "")))
        }

        let contact: [(String, String)] = [
            ("Name", "\(form.firstName.trimmed) \(form.lastName.trimmed)"),
            ("Email", form.email),
            ("Phone", form.phone),
            ("Role", form.role),
            ("Company", form.company),
            ("Preferred contact", form.contactPreference.rawValue)
        ]

        var terms: [(String, String)] = [
            ("Property", form.propertyLine),
            ("Property type", form.propertyType),
            ("APN", form.apn)
        ]
        if isPurchase {
            terms += [
                ("Purchase price", form.salePrice),
                ("Initial deposit", form.deposit),
                ("Acceptance date", Format.reviewDate(form.acceptanceDate)),
                ("Target close", Format.reviewDate(form.closeDate)),
                ("Buyer(s)", form.buyerNames),
                ("Seller(s)", form.sellerNames),
                ("Financing", form.financing),
                ("Other side's agent", form.otherAgent)
            ]
        } else {
            terms += [
                ("New loan amount", form.loanAmount),
                ("Lender", form.lender),
                ("Borrower(s)", form.borrowerNames),
                ("Loan officer", form.loanOfficer),
                ("Refinance type", form.refinanceType),
                ("Target funding", Format.reviewDate(form.fundDate))
            ]
        }
        terms.append(("Notes", form.notes))

        var documents: [(String, String)] = [(type.documentShortName, form.documentStatus?.rawValue ?? "")]
        if form.documentStatus == .agentOrLenderWillSend {
            let sender = [form.senderName.trimmed, form.senderEmail.trimmed].filter { !$0.isEmpty }.joined(separator: ", ")
            documents.append(("Sending it", sender))
        }

        func rows(_ pairs: [(String, String)]) -> [ReviewRow] {
            pairs.filter { !$0.1.isBlank }.map { ReviewRow(key: $0.0, value: $0.1.trimmed) }
        }

        return [
            ReviewSection(title: "Transaction", step: 1, rows: rows(transaction)),
            ReviewSection(title: "Contact", step: 2, rows: rows(contact)),
            ReviewSection(title: "Property & terms", step: 3, rows: rows(terms)),
            ReviewSection(title: "Documents", step: 4, rows: rows(documents))
        ]
    }
}
