import SwiftUI
import UIKit

/// Requests: the draft in progress and every request sent from this iPhone, with its reference.
struct RequestsView: View {
    @Environment(AppModel.self) private var app
    @Environment(RequestStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if store.sent.isEmpty && store.draft == nil {
                        emptyState
                    } else {
                        Text("Saved on this iPhone, so your reference is always handy.")
                            .font(.callout)
                            .foregroundStyle(Palette.text2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 18)

                        if let draft = store.draft {
                            DraftCard(draft: draft, resume: { app.resumeDraft() }, delete: { withAnimation { store.discardDraft() } })
                                .padding(.bottom, 24)
                        }

                        if let latest = store.sent.first {
                            SectionLabel("Sent to Escrow Logix")
                            RequestCard(request: latest)
                                .contextMenu { removeButton(latest) }
                        }

                        let older = Array(store.sent.dropFirst())
                        if !older.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(older.enumerated()), id: \.element.id) { index, request in
                                    if index > 0 { RowDivider(inset: 61) }
                                    NavigationLink(value: request) {
                                        OlderRequestRow(request: request)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu { removeButton(request) }
                                }
                            }
                            .card()
                            .padding(.top, 12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .background(Palette.bg)
            .navigationTitle("Requests")
            .navigationDestination(for: SentRequest.self) { request in
                ScrollView {
                    RequestCard(request: request)
                        .padding(20)
                }
                .background(Palette.bg)
                .navigationTitle(request.street.isEmpty ? request.type.title : request.street)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Brand.gold2)
                .frame(width: 72, height: 72)
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityHidden(true)
            Text("No requests yet")
                .font(.cardTitle)
                .foregroundStyle(Palette.heading)
            Text("Requests you send from this iPhone show up here with their reference, so it's always handy when you call.")
                .font(.callout)
                .foregroundStyle(Palette.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open an escrow") {
                app.startIntake()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 260)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func removeButton(_ request: SentRequest) -> some View {
        Button("Remove from this iPhone", systemImage: "trash", role: .destructive) {
            withAnimation { store.remove(request) }
        }
    }
}

extension SentRequest: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(reference)
    }
}

/// The draft in progress, with Resume.
private struct DraftCard: View {
    let draft: IntakeDraft
    let resume: () -> Void
    let delete: () -> Void

    var body: some View {
        let type = draft.form.type
        HStack(spacing: 13) {
            Image(systemName: type?.symbol ?? "square.and.pencil")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Palette.heading)
                .frame(width: 46, height: 46)
                .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Kicker("Draft")
                Text(type?.title ?? "Open Escrow")
                    .font(.headline)
                    .foregroundStyle(Palette.heading)
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text("Step \(draft.step) of 5 · \(Self.age(of: draft.savedAt, now: context.date))")
                        .font(.footnote)
                        .foregroundStyle(Palette.text2)
                }
            }
            Spacer(minLength: 8)
            Button("Resume", action: resume)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryForeground)
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .background(Palette.primaryBackground, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .card()
        .contextMenu {
            Button("Resume", systemImage: "arrow.uturn.forward", action: resume)
            Button("Delete draft", systemImage: "trash", role: .destructive, action: delete)
        }
    }

    /// "just now", "2 min ago", "3 hr ago", "Sep 21".
    static func age(of date: Date, now: Date) -> String {
        let seconds = max(now.timeIntervalSince(date), 0)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60)) min ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600)) hr ago" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

/// A sent request: status, address, reference, time, document, and what you can do next.
private struct RequestCard: View {
    let request: SentRequest
    @State private var upload: WebLink?
    @State private var showsNotConnected = false
    @State private var copied = false

    private var shareFileURL: URL? { AppConfig.shareFile[request.type] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: request.type.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Brand.gold2)
                    .frame(width: 46, height: 46)
                    .background(Palette.tile, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.street.isEmpty ? request.type.title : request.street)
                        .font(.headline)
                        .foregroundStyle(Palette.heading)
                    Text([request.type.payloadName, request.cityLine].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(Palette.text2)
                }
                .padding(.top, 3)
                Spacer(minLength: 8)
                if request.prototype {
                    StatusPill(text: "Not sent", tint: Palette.text2)
                } else {
                    StatusPill(text: "Received")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                RowDivider()
                metaRow("Reference") {
                    HStack(spacing: 6) {
                        Text(request.reference)
                            .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = request.reference
                            copied = true
                        } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 28, height: 28)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(copied ? "Copied" : "Copy reference")
                        .sensoryFeedback(.success, trigger: copied) { _, isCopied in isCopied }
                    }
                }
                RowDivider()
                metaRow("Sent") { Text(Format.sentTime(request.sentAt)) }
                RowDivider()
                metaRow(request.type.documentShortName) { Text(documentLine) }
            }

            HStack(spacing: 10) {
                CallButton(location: "requests") {
                    Label("Call about it", systemImage: "phone.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryForeground)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Palette.primaryBackground, in: Capsule())
                }
                .buttonStyle(.plain)
                if request.documentStatus != .uploaded {
                    Button {
                        if let url = shareFileURL { upload = WebLink(url: url) } else { showsNotConnected = true }
                    } label: {
                        Label("Upload document", systemImage: "arrow.up.doc")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Palette.fill, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .card()
        .sheet(item: $upload) { link in
            NavigationStack {
                WebView(url: link.url)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Upload · \(request.reference)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { upload = nil }
                        }
                    }
            }
        }
        .alert("Secure upload isn't connected yet", isPresented: $showsNotConnected) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your escrow officer will send a secure upload link for the \(request.type.documentShortName). Mention reference \(request.reference) if you call.")
        }
    }

    private var documentLine: String {
        if request.documentStatus == .agentOrLenderWillSend, let sender = request.senderName {
            return "\(sender) is sending it"
        }
        return request.documentStatus.summary
    }

    private func metaRow<Value: View>(_ key: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(key)
                .foregroundStyle(Palette.text2)
                .fixedSize()
            Spacer(minLength: 0)
            value()
                .fontWeight(.semibold)
                .foregroundStyle(Palette.heading)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}

/// An earlier request, one line.
private struct OlderRequestRow: View {
    let request: SentRequest

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: request.type.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 32, height: 32)
                .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(request.street.isEmpty ? request.type.title : request.street)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Palette.heading)
                Text("\(request.type.payloadName) · \(request.sentAt.formatted(.dateTime.month(.abbreviated).day())) · \(request.reference)")
                    .font(.footnote)
                    .foregroundStyle(Palette.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.text3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
