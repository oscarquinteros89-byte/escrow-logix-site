import Foundation

/// Same event names and parameters as the website's Google Analytics plan,
/// so app and web numbers line up in one report. Never send form contents.
enum AnalyticsEvent: String {
    case escrowStep = "escrow_step"
    case generateLead = "generate_lead"
    case escrowSubmitFailed = "escrow_submit_failed"
    case clickToCall = "click_to_call"
    case faqOpen = "faq_open"
}

enum Analytics {
    /// Off until Escrow Logix chooses an analytics account.
    /// To turn on: add the Firebase Analytics package (GA4) and forward events here.
    static func track(_ event: AnalyticsEvent, _ parameters: [String: String] = [:]) {
        #if DEBUG
        let details = parameters.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        print("[analytics] \(event.rawValue) \(details)")
        #endif
    }
}
