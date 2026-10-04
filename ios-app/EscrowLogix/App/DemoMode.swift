#if DEBUG
import Foundation

/// Debug builds only: opens the app on a given screen with sample data, so screenshots can be made
/// from the command line. Nothing here is in the App Store build.
///
///     xcrun simctl launch booted com.escrowlogix.openescrow -demo step3-details
///
/// Screens: home, home-rep, step1, step2, step3-address, step3-details, step4, step4-sender,
/// step5, step5-submit, success, requests, requests-empty, contact, team, help, draft-choice.
/// Demo runs keep everything in memory, so they never touch saved requests.
enum DemoMode {
    /// The value after -demo on the command line (launch arguments land in UserDefaults).
    static var screen: String? {
        let value = UserDefaults.standard.string(forKey: "demo")
        return value?.isEmpty == false ? value : nil
    }

    @MainActor
    static func apply(to app: AppModel) {
        guard let screen else { return }

        switch screen {
        case "home-rep":
            app.attribution.apply(repLink)
            app.scrollAnchor = "rep"
        case "requests":
            app.requests.replaceAll(sent: sampleRequests, draft: sampleDraft)
            app.selectedTab = .requests
        case "requests-empty":
            app.selectedTab = .requests
        case "contact":
            app.selectedTab = .contact
        case "team":
            app.selectedTab = .contact
            app.scrollAnchor = "team"
        case "help":
            app.selectedTab = .help
            app.scrollAnchor = "What documents do I need?"
        case "draft-choice":
            app.requests.replaceAll(sent: [], draft: sampleDraft)
            present { app.startIntake(.purchase) }
        default:
            if let model = intake(for: screen, app: app) {
                present { app.activeIntake = model }
            }
        }
    }

    /// Opens the sheet once the window is on screen.
    @MainActor
    private static func present(_ action: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            action()
        }
    }

    @MainActor
    private static func intake(for screen: String, app: AppModel) -> IntakeModel? {
        var form = sampleForm
        let step: Int
        var scroll: IntakeModel.DemoScroll?

        switch screen {
        case "step1":
            form = IntakeForm(type: .purchase)
            step = 1
        case "step2":
            step = 2
        case "step3-address":
            step = 3
            form.street = "123 Main St"
            form.city = ""
            form.zip = ""
            scroll = IntakeModel.DemoScroll(field: .street, atBottom: false, focuses: true)
        case "step3-details":
            step = 3
            scroll = IntakeModel.DemoScroll(field: .city, atBottom: false)
        case "step4":
            step = 4
        case "step4-sender":
            step = 4
            scroll = IntakeModel.DemoScroll(field: .senderEmail)
        case "step5":
            step = 5
        case "step5-submit":
            step = 5
            form.consent = true
            scroll = IntakeModel.DemoScroll(field: .consent)
        case "success":
            step = 5
            form.consent = true
        default:
            return nil
        }

        // The design pictures show a request that came in through Andrea's rep link.
        app.attribution.apply(repLink)
        let model = IntakeModel(form: form, step: step, attribution: app.attribution, store: app.requests)
        model.demoScroll = scroll
        if screen == "success" {
            Task { @MainActor in await model.submit() }
        }
        return model
    }

    // MARK: Sample data (made up; matches the design pictures)

    private static let repLink = URL(string: "escrowlogix://open?rep=andrea-kawawaki")!

    private static func day(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return Calendar.current.date(from: parts) ?? .now
    }

    private static var sampleForm: IntakeForm {
        var form = IntakeForm(type: .purchase)
        form.firstName = "Jordan"
        form.lastName = "Reyes"
        form.email = "jordan.reyes@icloud.com"
        form.phone = "(818) 555-0142"
        form.role = "Buyer's Agent"
        form.company = "Northvale Realty"
        form.street = "123 Main Street"
        form.city = "Burbank"
        form.state = "CA"
        form.zip = "91502"
        form.propertyType = "Single-family residence"
        form.apn = "2441-012-019"
        form.salePrice = "$1,250,000"
        form.deposit = "$37,500"
        form.acceptanceDate = day(2026, 10, 3)
        form.closeDate = day(2026, 11, 2)
        form.buyerNames = "Chris & Taylor Morgan"
        form.sellerNames = "Pat Lee"
        form.financing = "Conventional"
        form.documentStatus = .agentOrLenderWillSend
        form.senderName = "Dana Park"
        form.senderEmail = "dana@lender.com"
        form.reference = "ELX-20261004-K7QM"
        return form
    }

    private static var sampleRequests: [SentRequest] {
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 9, minute: 38, second: 0, of: .now) ?? .now
        return [
            SentRequest(reference: "ELX-20261004-K7QM", type: .purchase, street: "123 Main Street",
                        cityLine: "Burbank, CA 91502", sentAt: today, documentStatus: .agentOrLenderWillSend,
                        senderName: nil, prototype: false),
            SentRequest(reference: "ELX-20260921-3RTA", type: .refinance, street: "456 Elm Street",
                        cityLine: "Glendale, CA 91203", sentAt: day(2026, 9, 21, 14, 12), documentStatus: .uploaded,
                        senderName: nil, prototype: false)
        ]
    }

    private static var sampleDraft: IntakeDraft {
        var form = IntakeForm(type: .refinance)
        form.firstName = "Jordan"
        form.lastName = "Reyes"
        form.email = "jordan.reyes@icloud.com"
        form.phone = "(818) 555-0142"
        form.role = "Borrower / Homeowner"
        return IntakeDraft(form: form, step: 3, savedAt: Date.now.addingTimeInterval(-120))
    }
}
#endif
