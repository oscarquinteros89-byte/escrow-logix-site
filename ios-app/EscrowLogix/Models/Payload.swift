import Foundation

/// Ordered JSON, so the payload reads in the same order as the website's and nulls are written out.
enum JSONValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case object([(String, JSONValue)])
    case array([JSONValue])

    func rendered(pretty: Bool = false) -> String {
        var out = ""
        write(into: &out, pretty: pretty, level: 0)
        return out
    }

    private func write(into out: inout String, pretty: Bool, level: Int) {
        switch self {
        case .string(let value):
            out += Self.quote(value)
        case .number(let value):
            out += Self.format(value)
        case .bool(let value):
            out += value ? "true" : "false"
        case .null:
            out += "null"
        case .array(let items):
            guard !items.isEmpty else { out += "[]"; return }
            out += "["
            for (index, item) in items.enumerated() {
                if index > 0 { out += "," }
                if pretty { out += "\n" + Self.indent(level + 1) }
                item.write(into: &out, pretty: pretty, level: level + 1)
            }
            if pretty { out += "\n" + Self.indent(level) }
            out += "]"
        case .object(let pairs):
            guard !pairs.isEmpty else { out += "{}"; return }
            out += "{"
            for (index, pair) in pairs.enumerated() {
                if index > 0 { out += "," }
                if pretty { out += "\n" + Self.indent(level + 1) }
                out += Self.quote(pair.0) + (pretty ? ": " : ":")
                pair.1.write(into: &out, pretty: pretty, level: level + 1)
            }
            if pretty { out += "\n" + Self.indent(level) }
            out += "}"
        }
    }

    private static func indent(_ level: Int) -> String {
        String(repeating: "  ", count: level)
    }

    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "null" }
        if value == value.rounded(), abs(value) < 1e15 { return String(Int64(value)) }
        return String(value)
    }

    private static func quote(_ value: String) -> String {
        var out = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }
}

/// Builds the same CRM payload as the website's buildPayload(), including the documents.sender proposal.
enum PayloadBuilder {
    static func payload(form: IntakeForm, attribution: Attribution, submittedAt: Date) -> JSONValue {
        let isPurchase = form.type != .refinance

        func text(_ value: String) -> JSONValue { .string(value.trimmed) }
        func optional(_ value: String) -> JSONValue { value.isBlank ? .null : .string(value.trimmed) }
        func money(_ value: String) -> JSONValue { Format.number(value).map(JSONValue.number) ?? .null }
        func date(_ value: Date?) -> JSONValue { Format.payloadDate(value).map(JSONValue.string) ?? .null }

        let contact: JSONValue = .object([
            ("firstName", text(form.firstName)),
            ("lastName", text(form.lastName)),
            ("email", text(form.email)),
            ("phone", text(form.phone)),
            ("role", text(form.role)),
            ("company", optional(form.company)),
            ("preferredContact", .string(form.contactPreference.rawValue))
        ])

        let property: JSONValue = .object([
            ("street", text(form.street)),
            ("city", text(form.city)),
            ("state", form.state.isBlank ? .string("CA") : text(form.state)),
            ("zip", text(form.zip)),
            ("propertyType", optional(form.propertyType)),
            ("apn", optional(form.apn))
        ])

        let purchase: JSONValue = isPurchase ? .object([
            ("price", money(form.salePrice)),
            ("deposit", money(form.deposit)),
            ("acceptanceDate", date(form.acceptanceDate)),
            ("targetCloseDate", date(form.closeDate)),
            ("buyers", optional(form.buyerNames)),
            ("sellers", optional(form.sellerNames)),
            ("financing", optional(form.financing)),
            ("otherSideAgent", optional(form.otherAgent))
        ]) : .null

        let refinance: JSONValue = isPurchase ? .null : .object([
            ("loanAmount", money(form.loanAmount)),
            ("lender", text(form.lender)),
            ("borrowers", optional(form.borrowerNames)),
            ("loanOfficer", optional(form.loanOfficer)),
            ("refinanceType", optional(form.refinanceType)),
            ("targetFundingDate", date(form.fundDate))
        ])

        let sender: JSONValue
        if form.documentStatus == .agentOrLenderWillSend, !(form.senderName.isBlank && form.senderEmail.isBlank) {
            sender = .object([("name", optional(form.senderName)), ("email", optional(form.senderEmail))])
        } else {
            sender = .null
        }

        let documents: JSONValue = .object([
            ("required", .string(isPurchase ? "Purchase Contract" : "1003")),
            ("status", .string(form.documentStatus?.rawValue ?? "")),
            ("sender", sender),
            ("storage", .string("ShareFile"))      // documents never travel in this payload
        ])

        let utmPairs: [(String, JSONValue)] = attribution.utm
            .sorted { $0.key < $1.key }
            .map { pair -> (String, JSONValue) in (pair.key, JSONValue.string(pair.value)) }
        let utm: JSONValue = .object(utmPairs)
        let attributionJSON: JSONValue = .object([
            ("repSlug", attribution.repSlug.map(JSONValue.string) ?? .null),
            ("repName", attribution.rep.map { JSONValue.string($0.name) } ?? .null),
            ("utm", utm),
            ("referrer", attribution.referrer.map(JSONValue.string) ?? .null),
            ("landingPage", attribution.landingPage.map(JSONValue.string) ?? .null),
            ("firstSeen", .string(Format.timestamp(attribution.firstSeen)))
        ])

        // Filled in later by Sales Manager review and the RBJ CSV reconciliation.
        let workflow: JSONValue = .object([
            ("stage", .string("New request")),
            ("escrowOfficer", .null),
            ("rbjEscrowNumber", .null),
            ("rbjStatus", .null)
        ])

        return .object([
            ("requestId", .string(form.reference ?? "")),
            ("submittedAt", .string(Format.timestamp(submittedAt))),
            ("source", .string(AppConfig.source)),
            ("transactionType", .string(isPurchase ? "Purchase" : "Refinance")),
            ("contact", contact),
            ("property", property),
            ("purchase", purchase),
            ("refinance", refinance),
            ("documents", documents),
            ("notes", optional(form.notes)),
            ("attribution", attributionJSON),
            ("workflow", workflow)
        ])
    }
}

/// Posts the payload. Native apps have no CORS preflight, so plain JSON works with any webhook.
enum CRMClient {
    struct HTTPStatusError: LocalizedError {
        let status: Int
        var errorDescription: String? { "HTTP \(status)" }
    }

    static func send(_ payload: JSONValue, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(payload.rendered().utf8)
        request.timeoutInterval = 30
        let (_, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw HTTPStatusError(status: status) }
    }
}
