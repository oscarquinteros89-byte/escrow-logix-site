import SwiftUI

/// Step 5: everything at a glance, with Edit links, and the consent statement.
struct StepReviewView: View {
    @Bindable var model: IntakeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepTitle(title: "Review and submit.",
                      subtitle: "Check the details below before sending your request to the Escrow Logix team.")

            ForEach(model.reviewSections) { section in
                if !section.rows.isEmpty {
                    header(for: section)
                    FieldGroup {
                        ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { RowDivider() }
                            ReviewRowView(row: row)
                        }
                    }
                }
            }

            Toggle(isOn: $model.form.consent) {
                Text("I confirm this information is accurate and I'm authorized to open this escrow. I agree that Escrow Logix may contact me about this request. Escrow is not opened until an Escrow Logix officer confirms it and issues an escrow number.")
                    .font(.footnote)
                    .foregroundStyle(Palette.text2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .toggleStyle(LeadingSwitchStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .card(radius: 20)
            .overlay {
                if model.error(.consent) != nil {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Palette.error, lineWidth: 1.5)
                }
            }
            .padding(.top, 22)
            .id(Field.consent)

            if let error = model.error(.consent) {
                ErrorNote(error)
            }
        }
    }

    private func header(for section: IntakeModel.ReviewSection) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Kicker(section.title)
            Spacer(minLength: 8)
            Button("Edit") {
                model.edit(step: section.step)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.accent)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .accessibilityLabel("Edit \(section.title)")
        }
        .padding(.horizontal, 4)
        .padding(.top, section.step == 1 ? 0 : 18)
        .padding(.bottom, 4)
    }
}

/// "Purchase price ......... $1,250,000". Stacks at the largest text sizes.
private struct ReviewRowView: View {
    let row: IntakeModel.ReviewRow
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    key
                    value
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    key.fixedSize()
                    Spacer(minLength: 0)
                    value.multilineTextAlignment(.trailing)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var key: some View {
        Text(row.key).foregroundStyle(Palette.text2)
    }

    private var value: some View {
        Text(row.value)
            .fontWeight(.semibold)
            .foregroundStyle(Palette.heading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
