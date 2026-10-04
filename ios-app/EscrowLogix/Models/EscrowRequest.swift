import Foundation

// The same questions, options and checks as the website's form (index.html, steps 1 to 5).

enum EscrowType: String, Codable, CaseIterable, Identifiable {
    case purchase
    case refinance

    var id: String { rawValue }

    var title: String { self == .purchase ? "Purchase Escrow" : "Refinance Escrow" }

    var summary: String {
        switch self {
        case .purchase: return "Buying or selling a home or investment property. You'll send the Purchase Contract."
        case .refinance: return "Refinancing an existing loan. You'll send the 1003 loan application."
        }
    }

    var symbol: String { self == .purchase ? "house" : "arrow.triangle.2.circlepath" }

    /// transactionType in the CRM payload.
    var payloadName: String { self == .purchase ? "Purchase" : "Refinance" }

    /// "Purchase Contract" or "1003 loan application".
    var documentName: String { self == .purchase ? "Purchase Contract" : "1003 loan application" }

    /// "Purchase Contract" or "1003" (documents.required in the payload).
    var documentShortName: String { self == .purchase ? "Purchase Contract" : "1003" }
}

enum ContactPreference: String, Codable, CaseIterable, Identifiable {
    case email = "Email"
    case phone = "Phone"
    case text = "Text"

    var id: String { rawValue }
}

/// Raw values are what the CRM maps, so they must stay as on the website.
enum DocumentStatus: String, Codable, CaseIterable, Identifiable {
    case uploaded = "Uploaded"
    case sendingLater = "Sending later"
    case agentOrLenderWillSend = "Agent/lender will send"

    var id: String { rawValue }

    func label(for type: EscrowType) -> String {
        switch self {
        case .uploaded: return "I've uploaded the \(type.documentShortName)"
        case .sendingLater: return "I'll send it later"
        case .agentOrLenderWillSend: return "My agent or lender will send it"
        }
    }

    /// Short wording for the Requests tab.
    var summary: String {
        switch self {
        case .uploaded: return "Uploaded"
        case .sendingLater: return "Sending later"
        case .agentOrLenderWillSend: return "Agent or lender sending"
        }
    }
}

enum FormOptions {
    static let roles = [
        "Listing Agent", "Buyer's Agent", "Loan Officer / Mortgage Professional", "Buyer", "Seller",
        "Borrower / Homeowner", "Attorney", "Investor", "Transaction Coordinator", "Other"
    ]
    static let propertyTypes = [
        "Single-family residence", "Condo / Townhome", "2–4 units", "5+ units / Multifamily", "Commercial", "Vacant land"
    ]
    static let financing = ["Conventional", "FHA", "VA", "Jumbo", "All cash", "Other"]
    static let refinanceTypes = ["Rate / term", "Cash-out", "HELOC / 2nd", "Other"]
}

/// Everything the person types. Saved as a draft while they work.
struct IntakeForm: Codable, Equatable {
    var type: EscrowType?

    // Step 2: contact
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var role = ""
    var company = ""
    var contactPreference: ContactPreference = .email

    // Step 3: property
    var street = ""
    var city = ""
    var state = "CA"
    var zip = ""
    var propertyType = ""
    var apn = ""

    // Step 3: purchase
    var salePrice = ""
    var deposit = ""
    var acceptanceDate: Date?
    var closeDate: Date?
    var buyerNames = ""
    var sellerNames = ""
    var financing = ""
    var otherAgent = ""

    // Step 3: refinance
    var loanAmount = ""
    var lender = ""
    var borrowerNames = ""
    var loanOfficer = ""
    var refinanceType = ""
    var fundDate: Date?

    var notes = ""

    // Step 4: documents
    var documentStatus: DocumentStatus?
    var senderName = ""
    var senderEmail = ""

    // Step 5
    var consent = false

    /// Created when the Documents step opens, so it can be typed into the upload form.
    var reference: String?

    init(type: EscrowType? = nil) {
        self.type = type
    }

    /// Whether there's anything worth keeping as a draft.
    var hasContent: Bool {
        let typed = [firstName, lastName, email, phone, company, street, city, zip, apn, salePrice, deposit,
                     buyerNames, sellerNames, otherAgent, loanAmount, lender, borrowerNames, loanOfficer, notes]
        return type != nil || !role.isEmpty || typed.contains { !$0.isBlank }
    }

    /// "123 Main Street, Burbank, CA 91502", as on the website's review step.
    var propertyLine: String {
        let stateZip = [state.trimmed, zip.trimmed].filter { !$0.isEmpty }.joined(separator: " ")
        return [street.trimmed, city.trimmed, stateZip].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var cityLine: String {
        let stateZip = [state.trimmed, zip.trimmed].filter { !$0.isEmpty }.joined(separator: " ")
        return [city.trimmed, stateZip].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// Every input, for focus, scrolling and error messages.
enum Field: Hashable {
    case firstName, lastName, email, phone, role, company
    case street, city, state, zip, propertyType, apn
    case salePrice, deposit, buyerNames, sellerNames, financing, otherAgent
    case loanAmount, lender, borrowerNames, loanOfficer, refinanceType
    case notes
    case documentStatus, senderName, senderEmail
    case consent
}

/// The website's validation rules and messages.
enum Validator {
    static func fields(onStep step: Int, type: EscrowType?) -> [Field] {
        switch step {
        case 2:
            return [.firstName, .lastName, .email, .phone, .role, .company]
        case 3:
            let common: [Field] = [.street, .city, .state, .zip, .propertyType, .apn]
            let specific: [Field] = type == .refinance
                ? [.loanAmount, .lender, .borrowerNames, .loanOfficer, .refinanceType]
                : [.salePrice, .deposit, .buyerNames, .sellerNames, .financing, .otherAgent]
            return common + specific + [.notes]
        case 4:
            return [.documentStatus, .senderName, .senderEmail]
        case 5:
            return [.consent]
        default:
            return []
        }
    }

    static func step(of field: Field) -> Int {
        switch field {
        case .firstName, .lastName, .email, .phone, .role, .company: return 2
        case .documentStatus, .senderName, .senderEmail: return 4
        case .consent: return 5
        default: return 3
        }
    }

    static func message(for field: Field, in form: IntakeForm) -> String? {
        switch field {
        case .firstName: return form.firstName.isBlank ? "Please enter a first name." : nil
        case .lastName: return form.lastName.isBlank ? "Please enter a last name." : nil
        case .email: return isEmail(form.email) ? nil : "Please enter a valid email."
        case .phone: return isPhone(form.phone) ? nil : "Please enter a 10-digit phone number."
        case .role: return form.role.isEmpty ? "Please choose your role." : nil
        case .street: return form.street.isBlank ? "Please enter the property address." : nil
        case .city: return form.city.isBlank ? "Please enter the city." : nil
        case .zip: return isZip(form.zip) ? nil : "5-digit ZIP."
        case .salePrice:
            return form.type != .refinance && Format.number(form.salePrice) == nil ? "Please enter the purchase price." : nil
        case .loanAmount:
            return form.type == .refinance && Format.number(form.loanAmount) == nil ? "Please enter the loan amount." : nil
        case .lender:
            return form.type == .refinance && form.lender.isBlank ? "Please enter the lender." : nil
        case .documentStatus:
            return form.documentStatus == nil ? "Please choose one so we know what to expect." : nil
        case .senderEmail:
            guard form.documentStatus == .agentOrLenderWillSend, !form.senderEmail.isBlank else { return nil }
            return isEmail(form.senderEmail) ? nil : "Please enter a valid email."
        case .consent:
            return form.consent ? nil : "Please confirm the statement above to submit."
        default:
            return nil
        }
    }

    static func firstInvalid(onStep step: Int, in form: IntakeForm) -> Field? {
        fields(onStep: step, type: form.type).first { message(for: $0, in: form) != nil }
    }

    static func isEmail(_ value: String) -> Bool {
        value.trimmed.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    static func isPhone(_ value: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "0123456789 ()+.-")
        let trimmed = value.trimmed
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        return trimmed.filter(\.isASCIIDigit).count >= 10
    }

    static func isZip(_ value: String) -> Bool {
        value.trimmed.range(of: #"^\d{5}(-\d{4})?$"#, options: .regularExpression) != nil
    }
}

/// Formatting that matches the website (money and phone tidy up when you leave the field).
enum Format {
    static func number(_ value: String) -> Double? {
        let cleaned = value.filter { $0.isASCIIDigit || $0 == "." }
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    static func money(_ value: String) -> String {
        guard let amount = number(value) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: NSNumber(value: amount)) ?? String(amount))
    }

    static func phone(_ value: String) -> String {
        var digits = value.filter(\.isASCIIDigit)
        if digits.count == 11, digits.hasPrefix("1") { digits.removeFirst() }
        guard digits.count == 10 else { return value }
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(middle)-\(last)"
    }

    private static let reviewFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()

    private static let payloadFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// 10/03/2026, like the website's review step.
    static func reviewDate(_ date: Date?) -> String {
        date.map(reviewFormatter.string(from:)) ?? ""
    }

    /// 2026-10-03, like an HTML date input.
    static func payloadDate(_ date: Date?) -> String? {
        date.map(payloadFormatter.string(from:))
    }

    /// 2026-10-04T16:38:12.345Z, like JavaScript's toISOString().
    static func timestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    /// "Today, 9:38 AM" or "Sep 21, 9:38 AM".
    static func sentTime(_ date: Date) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date) { return "Today, \(time)" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday, \(time)" }
        return date.formatted(.dateTime.month(.abbreviated).day()) + ", " + time
    }
}

/// ELX-20261004-K7QM, same alphabet as the website (no 0, O, 1 or I).
enum Reference {
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func make(on date: Date = .now) -> String {
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        let day = String(format: "%04d%02d%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        let suffix = String((0..<4).map { _ in alphabet.randomElement() ?? "X" })
        return "ELX-\(day)-\(suffix)"
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isBlank: Bool { trimmed.isEmpty }
}

extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
