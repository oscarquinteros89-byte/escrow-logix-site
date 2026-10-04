import SwiftUI

/// Step 3: the property and the deal terms.
struct StepTransactionView: View {
    @Bindable var model: IntakeModel
    var focus: FocusState<Field?>.Binding
    @State private var search = AddressSearch()

    private var showsSuggestions: Bool {
        focus.wrappedValue == .street && !search.suggestions.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepTitle(title: "Tell us about the transaction.",
                      subtitle: "Just the basics we need to route your file to the right escrow officer.")

            SectionLabel("Property")
            FieldGroup {
                LabeledField(label: "Property street address", text: $model.form.street, field: .street, focus: focus,
                             error: model.error(.street), prompt: "123 Main Street",
                             contentType: .fullStreetAddress,
                             onSubmit: { focus.wrappedValue = .city })
            }
            if showsSuggestions {
                suggestionList
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                FootNote("Pick a suggestion and we'll fill in the city, state and ZIP.")
            }

            FieldGroup {
                HStack(alignment: .top, spacing: 0) {
                    LabeledField(label: "City", text: $model.form.city, field: .city, focus: focus,
                                 error: model.error(.city), prompt: "City", contentType: .addressCity,
                                 onSubmit: { focus.wrappedValue = .zip })
                    FieldColumnDivider()
                    LabeledField(label: "State", text: $model.form.state, field: .state, focus: focus,
                                 contentType: .addressState, capitalization: .characters)
                        .frame(width: 76)
                    FieldColumnDivider()
                    LabeledField(label: "ZIP", text: $model.form.zip, field: .zip, focus: focus,
                                 error: model.error(.zip), prompt: "ZIP",
                                 keyboard: .numberPad, contentType: .postalCode, capitalization: .never)
                        .frame(width: 104)
                }
                .fixedSize(horizontal: false, vertical: true)
                RowDivider()
                MenuField(label: "Property type", selection: $model.form.propertyType,
                          options: FormOptions.propertyTypes, field: .propertyType, tag: "Optional")
                RowDivider()
                LabeledField(label: "APN", text: $model.form.apn, field: .apn, focus: focus,
                             tag: "If known", capitalization: .characters)
            }
            .padding(.top, 14)
            FootNote("Assessor's Parcel Number, found on the property tax bill or the title report.")

            if model.type == .purchase {
                purchaseDetails
            } else {
                refinanceDetails
            }

            SectionLabel("Anything we should know?")
                .padding(.top, 24)
            FieldGroup {
                NotesField(text: $model.form.notes, focus: focus)
            }
        }
        .animation(.smooth(duration: 0.25), value: showsSuggestions)
        .onChange(of: model.form.street) { _, street in
            if focus.wrappedValue == .street { search.update(query: street) }
        }
        .onChange(of: focus.wrappedValue) { _, field in
            // Back in the street field: show suggestions for what's already typed.
            if field == .street { search.update(query: model.form.street) } else { search.clear() }
        }
    }

    // MARK: Purchase

    private var purchaseDetails: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Purchase details")
                .padding(.top, 24)
            FieldGroup {
                HStack(alignment: .top, spacing: 0) {
                    LabeledField(label: "Purchase price", text: $model.form.salePrice, field: .salePrice, focus: focus,
                                 error: model.error(.salePrice), prompt: "$", keyboard: .decimalPad, capitalization: .never)
                    FieldColumnDivider()
                    LabeledField(label: "Initial deposit (EMD)", text: $model.form.deposit, field: .deposit, focus: focus,
                                 prompt: "$", keyboard: .decimalPad, capitalization: .never)
                }
                .fixedSize(horizontal: false, vertical: true)
                RowDivider()
                OptionalDateRow(label: "Acceptance date", date: $model.form.acceptanceDate)
                RowDivider()
                OptionalDateRow(label: "Target close of escrow", date: $model.form.closeDate)
                RowDivider()
                LabeledField(label: "Buyer name(s)", text: $model.form.buyerNames, field: .buyerNames, focus: focus,
                             onSubmit: { focus.wrappedValue = .sellerNames })
                RowDivider()
                LabeledField(label: "Seller name(s)", text: $model.form.sellerNames, field: .sellerNames, focus: focus,
                             onSubmit: { focus.wrappedValue = .otherAgent })
                RowDivider()
                MenuField(label: "Financing", selection: $model.form.financing,
                          options: FormOptions.financing, field: .financing, tag: "Optional")
                RowDivider()
                LabeledField(label: "Other side's agent", text: $model.form.otherAgent, field: .otherAgent, focus: focus,
                             prompt: "Name and brokerage", submitLabel: .done,
                             onSubmit: { focus.wrappedValue = nil })
            }
            FootNote("EMD is the earnest money deposit, the buyer's good-faith deposit.")
        }
    }

    // MARK: Refinance

    private var refinanceDetails: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Refinance details")
                .padding(.top, 24)
            FieldGroup {
                LabeledField(label: "New loan amount", text: $model.form.loanAmount, field: .loanAmount, focus: focus,
                             error: model.error(.loanAmount), prompt: "$", keyboard: .decimalPad, capitalization: .never)
                RowDivider()
                LabeledField(label: "Lender", text: $model.form.lender, field: .lender, focus: focus,
                             error: model.error(.lender), contentType: .organizationName,
                             onSubmit: { focus.wrappedValue = .borrowerNames })
                RowDivider()
                LabeledField(label: "Borrower name(s)", text: $model.form.borrowerNames, field: .borrowerNames, focus: focus,
                             onSubmit: { focus.wrappedValue = .loanOfficer })
                RowDivider()
                LabeledField(label: "Loan officer", text: $model.form.loanOfficer, field: .loanOfficer, focus: focus,
                             prompt: "Name, phone, or email", submitLabel: .done,
                             onSubmit: { focus.wrappedValue = nil })
                RowDivider()
                MenuField(label: "Refinance type", selection: $model.form.refinanceType,
                          options: FormOptions.refinanceTypes, field: .refinanceType, tag: "Optional")
                RowDivider()
                OptionalDateRow(label: "Target funding date", date: $model.form.fundDate)
            }
        }
    }

    // MARK: Address suggestions

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Address suggestions", systemImage: "magnifyingglass")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.text3)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            ForEach(search.suggestions) { suggestion in
                if suggestion != search.suggestions.first {
                    RowDivider(inset: 60)
                }
                Button {
                    pick(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xEA4B3C), in: Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text(suggestion.title)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Palette.heading)
                            Text(suggestion.subtitle)
                                .font(.footnote)
                                .foregroundStyle(Palette.text2)
                        }
                        .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .card(radius: 20)
    }

    private func pick(_ suggestion: AddressSearch.Suggestion) {
        Task {
            guard let address = await search.resolve(suggestion) else {
                model.form.street = suggestion.title
                search.clear()
                focus.wrappedValue = .city
                return
            }
            model.form.street = address.street
            if !address.city.isEmpty { model.form.city = address.city }
            if !address.state.isEmpty { model.form.state = address.state }
            if !address.zip.isEmpty { model.form.zip = address.zip }
            search.clear()
            focus.wrappedValue = address.zip.isEmpty ? .zip : nil
        }
    }
}
