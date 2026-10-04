import SwiftUI
import UIKit

// MARK: - Buttons

/// Full-width capsule. Charcoal in light mode, gold in dark mode, like the mockups.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.primaryForeground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Palette.primaryBackground, in: Capsule())
            .shadow(color: .black.opacity(isEnabled ? 0.16 : 0), radius: 12, y: 8)
            .opacity(isEnabled ? 1 : 0.38)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// The website's gold call to action.
struct GoldButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.black)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Brand.goldGradient, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
            .shadow(color: Brand.gold.opacity(0.28), radius: 12, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Outlined capsule for use on top of the dark hero photo.
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .modifier(DarkGlassCapsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

private struct DarkGlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear.interactive(), in: .capsule)
                .environment(\.colorScheme, .dark)
        } else {
            content
                .background(Color.white.opacity(0.12), in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5))
                .environment(\.colorScheme, .dark)
        }
    }
}

/// Round 44pt icon button: Liquid Glass on iOS 26, material before that.
struct CircleIconButton: View {
    let systemName: String
    let label: String
    var tint: Color = Palette.heading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .glassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Liquid Glass circle on iOS 26, a material circle on earlier versions.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else {
            self.background(.regularMaterial, in: Circle())
        }
    }
}

// MARK: - Text

/// Small uppercase gold label, like the website's .kicker.
struct Kicker: View {
    let text: String
    var color: Color = Palette.accent

    init(_ text: String, color: Color = Palette.accent) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.kicker)
            .tracking(1.5)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Section label above a group of fields or rows.
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Kicker(text)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small grey note under a group.
struct FootNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Palette.text2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.top, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Cards

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(Palette.surface, in: shape)
            .overlay {
                if scheme == .dark { shape.strokeBorder(Palette.separator, lineWidth: 0.5) }
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.05), radius: 14, y: 8)
    }
}

extension View {
    /// White rounded card (dark surface with a hairline in dark mode).
    func card(radius: CGFloat = 22) -> some View {
        modifier(CardStyle(radius: radius))
    }
}

/// Hairline between rows in a card.
struct RowDivider: View {
    var inset: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

/// Status chip with a dot, e.g. "Open now" or "Received".
struct StatusPill: View {
    let text: String
    var tint: Color = Palette.success

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .frame(minHeight: 26)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

// MARK: - Brand pieces

/// Gold E plus the company name, as in the website header.
struct Lockup: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            Image("LogoE")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 28 : 36, height: compact ? 28 : 36)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("ESCROW LOGIX")
                    .font(.system(size: compact ? 14 : 15.5, weight: .bold))
                    .tracking(compact ? 1.6 : 2)
                    .foregroundStyle(.white)
                if !compact {
                    Text("CALIFORNIA INDEPENDENT ESCROW")
                        .font(.system(size: 7.6, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(Color(hex: 0xC6C1B7))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Escrow Logix")
    }
}

/// The website's wire-fraud warning.
struct WireFraudCard: View {
    /// Adds the "never asks for bank or wiring information" line.
    var mentionsApp = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Brand.gold2)
                .frame(width: 42, height: 42)
                .background(Brand.charcoal, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("Protect yourself from wire fraud.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.heading)
                Text("Escrow Logix will never change wiring instructions by email or text. Before sending any funds, call your escrow officer at a phone number you've verified independently."
                     + (mentionsApp ? " This app never asks for bank or wiring information." : ""))
                    .font(.footnote)
                    .foregroundStyle(Palette.wireText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.wireBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.wireLine, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The request reference with a Copy button.
struct ReferenceCard: View {
    let reference: String
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text("YOUR REQUEST REFERENCE")
                    .font(.kicker)
                    .tracking(1.3)
                    .foregroundStyle(Palette.text2)
                Text(reference)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(Palette.heading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
            Button {
                UIPasteboard.general.string = reference
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    copied = false
                }
            } label: {
                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 36)
                    .background(Palette.fill, in: Capsule())
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copied ? "Copied" : "Copy reference")
            .sensoryFeedback(.success, trigger: copied) { _, isCopied in isCopied }
        }
        .padding(.vertical, 15)
        .padding(.leading, 18)
        .padding(.trailing, 16)
        .card()
        .accessibilityElement(children: .contain)
    }
}

/// Round headshot with the gold ring, falling back to initials.
struct Headshot: View {
    let photo: String?
    let name: String
    var size: CGFloat = 46
    var ring: CGFloat = 1.5

    var body: some View {
        Group {
            if let photo, UIImage(named: photo) != nil {
                Image(photo).resizable().scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(Brand.gold2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.charcoal)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Brand.gold.opacity(0.7), lineWidth: ring))
        .accessibilityHidden(true)
    }

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

/// Icon tile, title and subtitle row used in Contact and Requests.
struct ListRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showsChevron = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 32, height: 32)
                    .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Palette.heading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Palette.text2)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.text3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// "Your Escrow Logix contact" card, shown when the app was opened from a rep's link.
struct RepCard: View {
    let rep: Rep
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 13) {
                Headshot(photo: rep.photo, name: rep.name, size: 54, ring: 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR ESCROW LOGIX CONTACT")
                        .font(.kicker)
                        .tracking(1.2)
                        .foregroundStyle(Palette.accent)
                    Text(rep.name)
                        .font(.headline)
                        .foregroundStyle(Palette.heading)
                    if let title = rep.title {
                        Text(title)
                            .font(.footnote)
                            .foregroundStyle(Palette.text2)
                    }
                }
                Spacer(minLength: 8)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.text3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .card()
    }
}
