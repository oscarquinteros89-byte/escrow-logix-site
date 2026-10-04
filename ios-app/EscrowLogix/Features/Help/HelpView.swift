import SwiftUI

/// Help: the wire-fraud warning, the website's FAQ adapted for the app, and what the app keeps.
struct HelpView: View {
    @Environment(AppModel.self) private var app
    @State private var web: WebLink?
    @State private var openQuestion: String?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        WireFraudCard(mentionsApp: true)

                        SectionLabel("Before you open escrow")
                            .padding(.top, 24)
                        VStack(spacing: 0) {
                            ForEach(Array(FAQ.items.enumerated()), id: \.element.question) { index, item in
                                if index > 0 { RowDivider() }
                                FAQRow(item: item, isOpen: openQuestion == item.question) {
                                    toggle(item)
                                }
                                .id(item.question)
                            }
                        }
                        .card()

                        SectionLabel("This app")
                            .padding(.top, 24)
                        VStack(spacing: 0) {
                            ListRow(icon: "lock.shield", title: "What stays on this iPhone",
                                    subtitle: "Drafts and the references of requests you send") {
                                toggleStorage()
                            }
                            if openQuestion == Self.storageKey {
                                Text("Your draft and a short record of each request you send (reference, address and document status) stay on this iPhone, encrypted while it's locked. Documents are never stored in the app. Remove a request any time by pressing and holding it in Requests.")
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 16)
                                    .padding(.leading, 45)
                                    .padding(.bottom, 14)
                                    .transition(.opacity)
                            }
                            RowDivider(inset: 61)
                            ListRow(icon: "globe", title: "escrowlogix.com", subtitle: "Services, about the team, and more") {
                                web = WebLink(url: Office.website)
                            }
                        }
                        .card()

                        VStack(spacing: 4) {
                            Text("Escrow Logix · Version \(Self.version)")
                            if AppConfig.isPrototype {
                                Text("Prototype: requests aren't sent to Escrow Logix yet.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Palette.text3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .background(Palette.bg)
                .navigationTitle("Help")
                .onAppear { applyAnchor(proxy) }
                .onChange(of: app.scrollAnchor) { _, _ in applyAnchor(proxy) }
            }
        }
        // Links inside answers: phone numbers call (and count as click_to_call), web pages open in the app.
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "tel" {
                Analytics.track(.clickToCall, ["link_location": "faq"])
                return .systemAction
            }
            if url.scheme == "https" {
                web = WebLink(url: url)
                return .handled
            }
            return .systemAction
        })
        .sheet(item: $web) { link in
            SafariView(url: link.url)
                .ignoresSafeArea()
        }
    }

    private static let storageKey = "storage"

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func toggle(_ item: FAQ) {
        withAnimation(.smooth(duration: 0.3)) {
            if openQuestion == item.question {
                openQuestion = nil
            } else {
                openQuestion = item.question
                Analytics.track(.faqOpen, ["faq_question": String(item.question.prefix(100))])
            }
        }
    }

    private func toggleStorage() {
        withAnimation(.smooth(duration: 0.3)) {
            openQuestion = openQuestion == Self.storageKey ? nil : Self.storageKey
        }
    }

    /// Demo screens can open one answer, by question.
    private func applyAnchor(_ proxy: ScrollViewProxy) {
        guard let anchor = app.scrollAnchor, let item = FAQ.items.first(where: { $0.question == anchor }) else { return }
        app.scrollAnchor = nil
        openQuestion = item.question
    }
}

/// The website's questions, with "this app" where the website says "this form" or "this website".
struct FAQ {
    let question: String
    /// Markdown, so links work.
    let answer: String

    static let items: [FAQ] = [
        FAQ(question: "Who can open escrow with this app?",
            answer: "Agents, loan officers, buyers, sellers, borrowers, attorneys, and transaction coordinators can all start a request. If you're opening on someone's behalf, include their names in the transaction step."),
        FAQ(question: "What documents do I need?",
            answer: "For a purchase, the fully executed Purchase Contract. For a refinance, the 1003 loan application. If it isn't ready yet, submit the request anyway and choose \"I'll send it later.\" Your escrow officer will follow up with a secure link."),
        FAQ(question: "Is my escrow open once I submit?",
            answer: "Not yet. Submitting sends your request to our team. Escrow is officially opened when your assigned officer confirms the order and issues an escrow number."),
        FAQ(question: "How is my information protected?",
            answer: "Contact and transaction details are sent to our team's secure system. Documents upload directly to our encrypted ShareFile portal and are never stored in this app."),
        FAQ(question: "How quickly will I hear back?",
            answer: "Escrow Logix opens orders the same day. The office is open Monday through Friday, 9am to 5pm Pacific, so a request sent after hours is picked up the next business day. You can always call [818.235.1225](tel:+18182351225)."),
        FAQ(question: "What kinds of escrow do you handle?",
            answer: "Residential, commercial and industrial, refinance, vacant land, for sale by owner, probate, 1031 exchanges, short sales and REOs, tracts and new construction, and wholesale transactions. Most of these start as a purchase: choose Purchase Escrow and add the details in the notes. [See all services](https://escrowlogix.com/services).")
    ]
}

/// A question that opens to show its answer.
private struct FAQRow: View {
    let item: FAQ
    let isOpen: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.question)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.heading)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isOpen ? Palette.accent : Palette.text3)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                Text(LocalizedStringKey(item.answer))
                    .font(.subheadline)
                    .foregroundStyle(Palette.text2)
                    .tint(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 15)
                    .padding(.top, -6)
                    .transition(.opacity)
            }
        }
    }
}
