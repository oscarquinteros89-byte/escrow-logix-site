import SwiftUI

/// Step 2: who's opening the escrow.
struct StepContactView: View {
    @Bindable var model: IntakeModel
    var focus: FocusState<Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepTitle(title: "Who's opening this escrow?",
                      subtitle: "We'll use this to confirm the order and send your escrow number.")

            FieldGroup {
                HStack(alignment: .top, spacing: 0) {
                    LabeledField(label: "First name", text: $model.form.firstName, field: .firstName, focus: focus,
                                 error: model.error(.firstName), contentType: .givenName,
                                 onSubmit: { focus.wrappedValue = .lastName })
                    FieldColumnDivider()
                    LabeledField(label: "Last name", text: $model.form.lastName, field: .lastName, focus: focus,
                                 error: model.error(.lastName), contentType: .familyName,
                                 onSubmit: { focus.wrappedValue = .email })
                }
                .fixedSize(horizontal: false, vertical: true)
                RowDivider()
                LabeledField(label: "Email", text: $model.form.email, field: .email, focus: focus,
                             error: model.error(.email), prompt: "name@example.com",
                             keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never,
                             onSubmit: { focus.wrappedValue = .phone })
                RowDivider()
                LabeledField(label: "Phone", text: $model.form.phone, field: .phone, focus: focus,
                             error: model.error(.phone), prompt: "(818) 555-0123",
                             keyboard: .phonePad, contentType: .telephoneNumber, capitalization: .never)
            }

            FieldGroup {
                MenuField(label: "Your role", selection: $model.form.role, options: FormOptions.roles,
                          field: .role, error: model.error(.role))
                RowDivider()
                LabeledField(label: "Company / brokerage", text: $model.form.company, field: .company, focus: focus,
                             tag: "Optional", contentType: .organizationName, submitLabel: .done,
                             onSubmit: { focus.wrappedValue = nil })
            }
            .padding(.top, 14)

            SectionLabel("Preferred contact method")
                .padding(.top, 24)
            Picker("Preferred contact method", selection: $model.form.contactPreference) {
                ForEach(ContactPreference.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
