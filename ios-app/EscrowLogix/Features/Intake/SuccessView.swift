import SwiftUI

/// The confirmation after submitting: reference, what happens next, and (prototype only) the CRM payload.
struct SuccessView: View {
    let model: IntakeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            burst
                .padding(.top, 6)
            Text("Request received.")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(Palette.heading)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.callout)
                .foregroundStyle(Palette.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 340)
                .padding(.top, 8)

            ReferenceCard(reference: model.reference)
                .padding(.top, 22)

            FieldGroup {
                NextStepRow(number: 1, text: "We review your request and match it with an escrow officer.")
                RowDivider(inset: 54)
                NextStepRow(number: 2, text: "Your officer confirms the order and sends your escrow number.")
                RowDivider(inset: 54)
                NextStepRow(number: 3, text: documentStep)
            }
            .padding(.top, 16)

            if let payload = model.payloadPreview {
                PayloadPreview(json: payload)
                    .padding(.top, 16)
            }
        }
        .onAppear { appeared = true }
    }

    private var message: String {
        if AppConfig.isPrototype {
            return "Prototype mode: this is exactly what a client will see after submitting. Nothing was sent to Escrow Logix."
        }
        let channel: String
        switch model.form.contactPreference {
        case .email: channel = "by email"
        case .phone: channel = "by phone"
        case .text: channel = "by text"
        }
        return "Thank you. Our team will review your request and assign an escrow officer. You'll hear from us \(channel), usually the same business day."
    }

    private var documentStep: String {
        model.form.documentStatus == .uploaded
            ? "Your document is already with us, so there's nothing else you need to send right now."
            : "Your officer will send a secure upload link for the \(model.type.documentShortName)."
    }

    private var burst: some View {
        let shown = appeared || reduceMotion
        return ZStack {
            Circle()
                .strokeBorder(Brand.green.opacity(0.08), lineWidth: 1.5)
                .frame(width: 132, height: 132)
                .scaleEffect(shown ? 1 : 0.7)
            Circle()
                .strokeBorder(Brand.green.opacity(0.18), lineWidth: 1.5)
                .frame(width: 104, height: 104)
                .scaleEffect(shown ? 1 : 0.8)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0x36906E), Color(hex: 0x256A51)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .shadow(color: Brand.green.opacity(0.32), radius: 15, y: 14)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(shown ? 1 : 0.5)
        }
        .frame(width: 132, height: 132)
        .opacity(shown ? 1 : 0)
        .animation(.spring(duration: 0.6, bounce: 0.45), value: shown)
        .accessibilityHidden(true)
    }
}

private struct NextStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Text("\(number)")
                .font(.footnote.weight(.heavy))
                .foregroundStyle(Palette.accent)
                .frame(width: 25, height: 25)
                .background(Palette.surface2, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

/// The JSON the CRM would receive. Only shown in prototype mode, like the website's developer box.
private struct PayloadPreview: View {
    let json: String
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(json)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(Palette.text)
                    .textSelection(.enabled)
                    .padding(.top, 10)
                    .fixedSize()
            }
        } label: {
            Label("Developer preview: CRM payload", systemImage: "curlybraces")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.heading)
        }
        .tint(Palette.accent)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.sunk, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
