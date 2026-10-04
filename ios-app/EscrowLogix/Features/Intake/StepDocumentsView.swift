import SwiftUI
import UIKit

/// Step 4: the request reference, the secure upload, and what to expect for the document.
struct StepDocumentsView: View {
    @Bindable var model: IntakeModel
    var focus: FocusState<Field?>.Binding
    @State private var upload: WebLink?
    @State private var showsNotConnected = false

    private var type: EscrowType { model.type }
    private var isConnected: Bool { model.shareFileURL != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepTitle(title: "Send your document securely.",
                      subtitle: "It goes straight to Escrow Logix's encrypted portal and never passes through this app.")

            ReferenceCard(reference: model.reference)
            FootNote(isConnected
                     ? "Type it in the upload form's Request reference box so we can match your file."
                     : "Keep it handy. It's how we match your document to this request.")
                .padding(.bottom, 14)

            uploadCard

            SectionLabel("Document status")
                .padding(.top, 24)
            FieldGroup {
                ForEach(DocumentStatus.allCases) { status in
                    if status != DocumentStatus.allCases.first {
                        RowDivider()
                    }
                    OptionRow(title: status.label(for: type), selected: model.form.documentStatus == status) {
                        withAnimation(.smooth(duration: 0.25)) {
                            model.form.documentStatus = status
                        }
                    }
                }
                if model.form.documentStatus == .agentOrLenderWillSend {
                    senderFields
                        .transition(.opacity)
                }
            }
            .id(Field.documentStatus)

            if let error = model.error(.documentStatus) {
                ErrorNote(error)
            } else if model.form.documentStatus == .agentOrLenderWillSend {
                FootNote("Helps us follow up on the document.")
            }
        }
        .sheet(item: $upload) { link in
            UploadSheet(url: link.url, title: "Upload your \(type.documentShortName)", reference: model.reference)
        }
        .alert("Secure upload isn't connected yet", isPresented: $showsNotConnected) {
            Button("Choose \"I'll send it later\"") {
                model.form.documentStatus = .sendingLater
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("This preview isn't linked to Escrow Logix's ShareFile portal yet. You can still submit, and your officer will send a secure upload link.")
        }
    }

    // MARK: Upload card

    private var uploadCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "lock")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Brand.gold2)
                .frame(width: 46, height: 46)
                .background(Brand.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Brand.gold.opacity(0.3), lineWidth: 1))
                .accessibilityHidden(true)
            Text("Upload your \(type.documentName)")
                .font(.cardTitle)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Text(isConnected
                 ? "Opens our encrypted ShareFile portal right here in the app. Only the Escrow Logix team can see what you upload."
                 : "Our encrypted ShareFile portal opens right here in the app once it's connected. Only the Escrow Logix team can see what you upload.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: 0xC8C5BE))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Button {
                openUpload()
            } label: {
                Label("Open secure upload", systemImage: "arrow.up.doc")
            }
            .buttonStyle(GoldButtonStyle(height: 48))
            .padding(.top, 14)

            Rectangle()
                .fill(Color.white.opacity(0.09))
                .frame(height: 1)
                .padding(.top, 16)
            VStack(alignment: .leading, spacing: 7) {
                bullet("Your \(type.documentName) uploads straight to our encrypted ShareFile portal.")
                bullet("This app never stores your documents.")
                bullet("Please don't upload bank statements, ID, or wiring details unless your escrow officer asks.")
            }
            .padding(.top, 12)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [Color(hex: 0x23272B), Color(hex: 0x15171A)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Brand.gold.opacity(0.22), Brand.gold.opacity(0)],
                               center: .center, startRadius: 0, endRadius: 110)
                    .frame(width: 220, height: 220)
                    .offset(x: 60, y: -70)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Brand.gold)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color(hex: 0xE2DED6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Who's sending it

    private var senderFields: some View {
        VStack(spacing: 0) {
            LabeledField(label: "Who's sending it?", text: $model.form.senderName, field: .senderName, focus: focus,
                         tag: "Optional", prompt: "Name", contentType: .name,
                         onSubmit: { focus.wrappedValue = .senderEmail })
                .padding(.leading, 37)
            RowDivider(inset: 53)
            LabeledField(label: "Their email", text: $model.form.senderEmail, field: .senderEmail, focus: focus,
                         error: model.error(.senderEmail), tag: "Optional", prompt: "name@example.com",
                         keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never,
                         submitLabel: .done, onSubmit: { focus.wrappedValue = nil })
                .padding(.leading, 37)
        }
        .background(Palette.sunk)
    }

    private func openUpload() {
        focus.wrappedValue = nil
        if let url = model.shareFileURL {
            upload = WebLink(url: url)
        } else {
            showsNotConnected = true
        }
    }
}

/// ShareFile's upload form in a sheet, with the reference pinned on top so it's easy to copy in.
private struct UploadSheet: View {
    let url: URL
    let title: String
    let reference: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Request reference")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(reference)
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .textSelection(.enabled)
                        }
                        Spacer(minLength: 8)
                        Button(copied ? "Copied" : "Copy") {
                            UIPasteboard.general.string = reference
                            copied = true
                        }
                        .buttonStyle(.bordered)
                        .tint(Palette.accent)
                        .sensoryFeedback(.success, trigger: copied) { _, isCopied in isCopied }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bar)
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
