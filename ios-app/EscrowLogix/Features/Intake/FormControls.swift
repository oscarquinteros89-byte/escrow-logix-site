import SwiftUI

/// Big title and one line of help at the top of each step.
struct StepTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.stepTitle)
                .foregroundStyle(Palette.heading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Palette.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// White rounded group of fields, like an iOS inset list.
struct FieldGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 20)
    }
}

/// Thin vertical line between side-by-side fields.
struct FieldColumnDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(width: 0.5)
            .padding(.vertical, 12)
    }
}

/// Label above the value, with an optional "Optional" tag and an error under it.
struct LabeledField: View {
    let label: String
    @Binding var text: String
    let field: Field
    var focus: FocusState<Field?>.Binding
    var error: String? = nil
    var tag: String? = nil
    var prompt: String = ""
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var capitalization: TextInputAutocapitalization = .words
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.fieldLabel)
                    .foregroundStyle(error != nil ? Palette.error : (isFocused ? Palette.accent : Palette.text2))
                Spacer(minLength: 0)
                if let tag {
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(Palette.text3)
                }
            }
            TextField(label, text: $text, prompt: Text(prompt).foregroundStyle(Palette.text3))
                .font(.body)
                .foregroundStyle(Palette.text)
                .tint(Brand.gold)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()   // names, addresses and numbers; Notes keeps autocorrect
                .submitLabel(submitLabel)
                .focused(focus, equals: field)
                .onSubmit(onSubmit)
                .accessibilityHint(error ?? "")
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { focus.wrappedValue = field }
        .id(field)
    }
}

/// Multi-line notes field.
struct NotesField: View {
    @Binding var text: String
    var focus: FocusState<Field?>.Binding

    var body: some View {
        TextField("Anything we should know?", text: $text,
                  prompt: Text("Timelines, special circumstances, preferred escrow officer, other parties to loop in…")
                    .foregroundStyle(Palette.text3),
                  axis: .vertical)
            .lineLimit(3...8)
            .font(.body)
            .foregroundStyle(Palette.text)
            .tint(Brand.gold)
            .focused(focus, equals: .notes)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = .notes }
            .id(Field.notes)
    }
}

/// A pick-one menu (role, property type, financing, refinance type).
struct MenuField: View {
    let label: String
    @Binding var selection: String
    let options: [String]
    var field: Field
    var tag: String? = nil
    var error: String? = nil
    var placeholder = "Select one"

    var body: some View {
        Menu {
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            if tag != nil, !selection.isEmpty {
                Divider()
                Button("Clear", role: .destructive) { selection = "" }
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(label)
                            .font(.fieldLabel)
                            .foregroundStyle(error != nil ? Palette.error : Palette.text2)
                        Spacer(minLength: 0)
                        if let tag {
                            Text(tag)
                                .font(.caption)
                                .foregroundStyle(Palette.text3)
                        }
                    }
                    Text(selection.isEmpty ? placeholder : selection)
                        .font(.body)
                        .foregroundStyle(selection.isEmpty ? Palette.text3 : Palette.text)
                        .lineLimit(1)
                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Palette.error)
                    }
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.text3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(selection.isEmpty ? "Not chosen" : selection)
        .id(field)
    }
}

/// A date that can be left empty: "Add date" until one is picked.
struct OptionalDateRow: View {
    let label: String
    @Binding var date: Date?

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.body)
                .foregroundStyle(Palette.text)
            Spacer(minLength: 8)
            if date != nil {
                DatePicker(label, selection: Binding(get: { date ?? .now }, set: { date = $0 }), displayedComponents: .date)
                    .labelsHidden()
                    .tint(Palette.accent)
                Button {
                    date = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Palette.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear \(label)")
            } else {
                Button("Add date") {
                    date = Calendar.current.startOfDay(for: .now)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .accessibilityLabel("Add \(label)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
    }
}

/// Purchase or refinance card on step 1.
struct ChoiceCard: View {
    let type: EscrowType
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        Button(action: action) {
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: type.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(selected ? Brand.gold2 : Palette.heading)
                    .frame(width: 52, height: 52)
                    .background(selected ? Palette.tile : Palette.surface2,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    Text(type.title)
                        .font(.cardTitle)
                        .foregroundStyle(Palette.heading)
                    Text(type.summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
                .padding(.trailing, 26)
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Palette.selectedCard : Palette.surface, in: shape)
            .overlay(shape.strokeBorder(selected ? Brand.gold : Palette.line, lineWidth: 1.5))
            .background(shape.stroke(Brand.gold.opacity(selected ? 0.18 : 0), lineWidth: 8))
            .overlay(alignment: .topTrailing) {
                RadioMark(selected: selected, size: 26)
                    .padding(18)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// Gold check in a circle when selected, an empty ring when not.
struct RadioMark: View {
    let selected: Bool
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            if selected {
                Circle().fill(Brand.gold)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(Brand.black)
            } else {
                Circle().strokeBorder(Palette.radio, lineWidth: 1.6)
            }
        }
        .frame(width: size, height: size)
        .animation(.snappy(duration: 0.2), value: selected)
    }
}

/// One choice in a list, like "I'll send it later".
struct OptionRow: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                RadioMark(selected: selected)
                Text(title)
                    .font(.body.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// Red note under a group, for choices that aren't text fields.
struct ErrorNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Label(text, systemImage: "exclamationmark.circle")
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.error)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The system switch on the left and a long statement beside it (the consent box).
/// The whole card is the tap target, and VoiceOver reads it as one switch.
struct LeadingSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Toggle("", isOn: configuration.$isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(Brand.gold)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}

/// Five gold segments under the sheet title.
struct ProgressSegments: View {
    let step: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...5, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AnyShapeStyle(Brand.progressGradient) : AnyShapeStyle(Palette.track))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 4)
        .animation(.smooth(duration: 0.35), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(min(step, 5)) of 5")
    }
}
