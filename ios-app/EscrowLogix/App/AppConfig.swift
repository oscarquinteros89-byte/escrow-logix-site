import Foundation

/// The only settings that change between prototype and production, mirroring the website's CONFIG block.
enum AppConfig {
    /// Webhook that receives the JSON payload (Pipedrive adapter, Zapier, Make, custom).
    /// nil = prototype mode: nothing is transmitted.
    static let crmEndpoint: URL? = nil

    /// ShareFile Remote Upload Form addresses. Empty = the upload card explains it isn't connected yet.
    static let shareFile: [EscrowType: URL] = [:]

    /// Rep link directory. Keys are slugs; case, dashes and spaces are ignored.
    /// Reps not listed still work: "JaneSmith" shows as "Jane Smith".
    static let reps: [String: Rep] = [
        "andrea-kawawaki": Rep(name: "Andrea Kawawaki", title: "Senior Sales Representative", photo: "AndreaKawawaki")
    ]

    /// Lands in the CRM's source field, next to the website's "Website – Open Escrow".
    static let source = "iPhone App – Open Escrow"

    static var isPrototype: Bool { crmEndpoint == nil }
}

/// Office facts, same as the website's footer and contact card.
enum Office {
    static let phoneDisplay = "818.235.1225"
    static let phoneURL = URL(string: "tel:+18182351225")!
    static let phoneForContacts = "+1 818-235-1225"
    static let faxDisplay = "818.235.5556"
    static let faxForContacts = "+1 818-235-5556"
    static let street = "16600 Sherman Way Ste 100"
    static let city = "Van Nuys"
    static let state = "CA"
    static let zip = "91406"
    static var cityLine: String { "\(city), \(state) \(zip)" }
    static let hours = "Mon–Fri, 9am–5pm PT"
    static let directionsURL = URL(string: "https://maps.apple.com/?daddr=16600+Sherman+Way+Ste+100,+Van+Nuys,+CA+91406")!
    static let website = URL(string: "https://escrowlogix.com")!
    static let services = URL(string: "https://escrowlogix.com/services")!
    static let about = URL(string: "https://escrowlogix.com/about")!
    static let assistant = URL(string: "https://escrowlogix.com/assistant")!
    static let reviews = URL(string: "https://www.google.com/search?q=Escrow+Logix+reviews")!

    static let team: [TeamMember] = [
        TeamMember(name: "James Lough", title: "Escrow Manager / Senior Escrow Officer", photo: "JamesLough"),
        TeamMember(name: "Aidan Odel", title: "Escrow Officer", photo: "AidanOdel"),
        TeamMember(name: "Yesenia Meza", title: "Escrow Assistant", photo: "YeseniaMeza"),
        TeamMember(name: "Andrea Kawawaki", title: "Senior Sales Representative", photo: "AndreaKawawaki")
    ]
}

struct TeamMember: Identifiable, Hashable {
    let name: String
    let title: String
    let photo: String
    var id: String { name }
}

/// A rep from a rep link.
struct Rep: Equatable, Hashable {
    let name: String
    var title: String? = nil
    var photo: String? = nil
}

/// Office hours in Pacific time, for the "Open now" chip.
enum OfficeHours {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }()

    /// Holidays aren't known to the app, so a holiday reads as a normal weekday.
    static func status(at date: Date = .now) -> (isOpen: Bool, text: String) {
        let parts = calendar.dateComponents([.weekday, .hour], from: date)
        let weekday = parts.weekday ?? 1   // 1 = Sunday
        let hour = parts.hour ?? 0
        let isWeekday = (2...6).contains(weekday)
        if isWeekday && (9..<17).contains(hour) { return (true, "Open now · until 5 PM") }
        if isWeekday && hour < 9 { return (false, "Closed · opens at 9 AM") }
        if (2...5).contains(weekday) { return (false, "Closed · opens tomorrow at 9 AM") }
        return (false, "Closed · opens Monday at 9 AM")
    }
}
