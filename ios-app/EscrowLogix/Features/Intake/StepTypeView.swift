import SwiftUI

/// Step 1: purchase or refinance.
struct StepTypeView: View {
    @Bindable var model: IntakeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StepTitle(title: "What are you opening?",
                      subtitle: "Choose the transaction type and we'll tailor the next steps.")
            ForEach(EscrowType.allCases) { type in
                ChoiceCard(type: type, selected: model.form.type == type) {
                    model.choose(type)
                }
            }
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(Palette.accent)
                Text("Have your Purchase Contract or 1003 loan application handy. If it isn't ready, you can still submit and send it later.")
                    .font(.footnote)
                    .foregroundStyle(Palette.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 4)
        }
    }
}
