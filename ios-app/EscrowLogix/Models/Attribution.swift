import Foundation

/// Rep credit and campaign tags, like the website's captureAttribution().
///
/// Rep links: escrowlogix://open?rep=andrea-kawawaki, escrowlogix://andrea-kawawaki
/// or escrowlogix://rep/andrea-kawawaki. UTM tags ride along as query items.
/// As on the website today, rep credit lasts for this app session only.
/// (A 30-day option is an open question for OB.)
struct Attribution: Equatable {
    var repRaw: String?
    var utm: [String: String] = [:]
    var referrer: String?
    var landingPage: String?
    var firstSeen: Date

    private static let utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"]
    private static let reservedPaths: Set<String> = [
        "open", "open-escrow", "openescrow", "contact", "about", "services", "faq", "privacy", "assistant",
        "purchase", "refinance"
    ]
    private static let firstSeenKey = "elx.firstSeen"

    /// Starts a session, keeping the first time this iPhone opened the app.
    static func current(defaults: UserDefaults = .standard) -> Attribution {
        let stored = defaults.double(forKey: firstSeenKey)
        if stored > 0 {
            return Attribution(firstSeen: Date(timeIntervalSince1970: stored))
        }
        let now = Date()
        defaults.set(now.timeIntervalSince1970, forKey: firstSeenKey)
        return Attribution(firstSeen: now)
    }

    /// Lowercase letters and digits only, so "Andrea-Kawawaki" and "andreakawawaki" match.
    static func key(_ value: String?) -> String {
        (value ?? "").lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

    /// "JaneSmith" or "jane-smith" becomes "Jane Smith".
    static func name(fromSlug slug: String) -> String {
        var spaced = ""
        var previous: Character?
        for character in slug {
            if let previous, previous.isLowercase, character.isUppercase { spaced.append(" ") }
            spaced.append(character)
            previous = character
        }
        let words = spaced
            .replacingOccurrences(of: "[-_.+]+", with: " ", options: .regularExpression)
            .lowercased()
            .split(separator: " ")
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    var repSlug: String? {
        let slug = Self.key(repRaw)
        return slug.isEmpty ? nil : slug
    }

    var rep: Rep? {
        guard let slug = repSlug, let raw = repRaw else { return nil }
        if let known = AppConfig.reps.first(where: { Self.key($0.key) == slug })?.value { return known }
        return Rep(name: Self.name(fromSlug: raw))
    }

    var repName: String? { rep?.name }

    /// Reads a rep link or campaign link. Returns the escrow type when the link asks to start one.
    @discardableResult
    mutating func apply(_ url: URL) -> EscrowType? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let items = components.queryItems ?? []
        func value(_ name: String) -> String? {
            guard let value = items.first(where: { $0.name.lowercased() == name })?.value?.trimmed, !value.isEmpty else { return nil }
            return value
        }

        // Path segments, counting the host of a custom-scheme link as the first one.
        var segments = url.pathComponents.filter { $0 != "/" }
        if url.scheme?.lowercased() == "escrowlogix", let host = url.host(), !host.isEmpty {
            segments.insert(host, at: 0)
        }

        if let rep = value("rep") {
            repRaw = rep
        } else if segments.count >= 2, ["open", "rep"].contains(segments[0].lowercased()),
                  !Self.reservedPaths.contains(segments[1].lowercased()) {
            repRaw = segments[1]
        } else if segments.count == 1, !Self.reservedPaths.contains(segments[0].lowercased()) {
            repRaw = segments[0]
        }

        var tags: [String: String] = [:]
        for key in Self.utmKeys {
            if let tag = value(key) { tags[key] = tag }
        }
        if !tags.isEmpty { utm = tags }
        if landingPage == nil { landingPage = url.absoluteString }

        let requested = value("type") ?? segments.first(where: { ["purchase", "refinance"].contains($0.lowercased()) })
        return requested.flatMap { EscrowType(rawValue: $0.lowercased()) }
    }
}
