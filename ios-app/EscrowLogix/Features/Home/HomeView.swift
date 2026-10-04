import SwiftUI

/// Home: the hero with both Open buttons, the numbers, the rep from a rep link,
/// how it works, and the wire-fraud warning. Same story and copy as the website's landing page.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    /// 0 while the hero is under the bar, 1 once content has scrolled under it. Steps of 0.1.
    @State private var barProgress: Double = 0

    var body: some View {
        NavigationStack {
            GeometryReader { outer in
                let safeTop = outer.safeAreaInsets.top
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            hero(safeTop: safeTop)
                            StatsCard()
                                .padding(.horizontal, 16)
                                .padding(.top, -40)
                            details(safeTop: safeTop)
                                .padding(.horizontal, 20)
                                .padding(.top, 26)
                                .padding(.bottom, 36)
                        }
                        .background(alignment: .top) {
                            GeometryReader { content in
                                let progress = Self.progress(forOffset: content.frame(in: .named("home")).minY)
                                Color.clear
                                    .onAppear { barProgress = progress }
                                    .onChange(of: progress) { _, value in barProgress = value }
                            }
                        }
                    }
                    .coordinateSpace(.named("home"))
                    .scrollIndicators(.hidden)
                    .background(Palette.bg)
                    .onAppear { scroll(proxy) }
                    .onChange(of: app.scrollAnchor) { _, _ in scroll(proxy) }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Lockup(compact: true)
                        .opacity(barProgress)
                        .accessibilityHidden(barProgress < 0.5)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CallButton(location: "header") {
                        callIcon
                    }
                    .accessibilityLabel("Call Escrow Logix")
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Brand.black.opacity(0.96 * barProgress), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    /// The bar darkens over the 64 points after the hero starts moving.
    private static func progress(forOffset offset: CGFloat) -> Double {
        let value = (-offset - 24) / 64
        return (min(max(value, 0), 1) * 10).rounded() / 10
    }

    @ViewBuilder
    private var callIcon: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: "phone.fill")
                .foregroundStyle(Brand.gold2)
        } else {
            Image(systemName: "phone.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Brand.gold2)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.14), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        guard let anchor = app.scrollAnchor, anchor == "rep" else { return }
        app.scrollAnchor = nil
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.smooth(duration: 0.5)) {
                proxy.scrollTo(anchor, anchor: .top)
            }
        }
    }

    // MARK: Hero

    private func hero(safeTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Lockup()
                .frame(height: 44)
                .padding(.top, max(safeTop - 44, 20))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Rectangle()
                        .fill(Brand.gold)
                        .frame(width: 30, height: 1)
                    Text("OPEN ESCROW")
                        .font(.kicker)
                        .tracking(1.9)
                        .foregroundStyle(Brand.goldLight)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Open Escrow")

                Text("A simpler start to a confident closing.")
                    .font(.heroTitle)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)

                Text("Open a purchase or refinance escrow in a few minutes. Tell us about the transaction, send your documents securely, and our team takes it from there.")
                    .font(.callout)
                    .foregroundStyle(Color(hex: 0xE2DFD9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                Button {
                    app.startIntake(.purchase)
                } label: {
                    HStack(spacing: 8) {
                        Text("Open a Purchase Escrow")
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .padding(.top, 20)

                Button("Open a Refinance Escrow") {
                    app.startIntake(.refinance)
                }
                .buttonStyle(GhostButtonStyle())
                .padding(.top, 10)

                TrustRow()
                    .padding(.top, 20)
            }
            .padding(.top, 34)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 62)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Pulling down past the top stretches the photo instead of showing a gap.
            GeometryReader { proxy in
                let pull = max(proxy.frame(in: .named("home")).minY, 0)
                HeroPhoto(size: CGSize(width: proxy.size.width, height: proxy.size.height + pull))
                    .offset(y: -pull)
            }
        }
    }

    // MARK: Below the hero

    private func details(safeTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let rep = app.attribution.rep {
                RepCard(rep: rep) { app.showTeam() }
                    // Scrolling to the rep card leaves room for the bar above it.
                    .padding(.top, safeTop + 16)
                    .id("rep")
                    .padding(.top, -(safeTop + 16))
                    .padding(.bottom, 26)
            }

            Kicker("How it works")
            Text("From request to open escrow, in four steps.")
                .font(.sectionTitle)
                .foregroundStyle(Palette.heading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Text("No phone tag and no emailed attachments. Here's what happens after you tap submit.")
                .font(.callout)
                .foregroundStyle(Palette.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            Timeline()
                .padding(.top, 20)

            WireFraudCard()
                .padding(.top, 6)

            VStack(spacing: 4) {
                Text("Licensed & bonded independent escrow company in California.")
                Text("\(Office.street), \(Office.cityLine)")
            }
            .font(.caption)
            .foregroundStyle(Palette.text3)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
        }
    }
}

/// The hero photo, framed like the website (focus a little right of center), under the dark shade.
private struct HeroPhoto: View {
    let size: CGSize
    private let aspect: CGFloat = 1920.0 / 1080.0

    var body: some View {
        let width = max(size.width, size.height * aspect)
        let height = width / aspect
        Brand.black
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) {
                Image("Hero")
                    .resizable()
                    .frame(width: width, height: height)
                    .offset(x: (size.width - width) * 0.63, y: (size.height - height) * 0.38)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0x0B0C0D, opacity: 0.62), location: 0),
                        .init(color: Color(hex: 0x0B0C0D, opacity: 0.10), location: 0.20),
                        .init(color: Color(hex: 0x0B0C0D, opacity: 0.18), location: 0.34),
                        .init(color: Color(hex: 0x0B0C0D, opacity: 0.78), location: 0.52),
                        .init(color: Color(hex: 0x0B0C0D, opacity: 0.96), location: 0.72),
                        .init(color: Brand.black, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// Licensed & bonded, Bank-grade security, Same-day opening.
private struct TrustRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            item("Licensed & bonded")
            item("Bank-grade security")
            item("Same-day opening")
        }
    }

    private func item(_ text: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Color(hex: 0xF0D4A0))
                .frame(width: 24, height: 24)
                .background(Brand.gold.opacity(0.16), in: Circle())
                .overlay(Circle().strokeBorder(Brand.gold.opacity(0.32), lineWidth: 1))
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: 0xF2EEE6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// The website's four numbers, in a card that overlaps the bottom of the hero.
private struct StatsCard: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                cell("30+", "Years of expertise")
                divider
                cell("$2.4B+", "Transactions closed")
            }
            .fixedSize(horizontal: false, vertical: true)
            RowDivider(inset: 0)
            HStack(spacing: 0) {
                cell("1,000's", "Closings completed")
                divider
                cell("100%", "Client satisfaction")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(Palette.surface, in: shape)
        .overlay {
            if scheme == .dark { shape.strokeBorder(Palette.separator, lineWidth: 0.5) }
        }
        .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.14), radius: 24, y: 18)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(width: 0.5)
    }

    private func cell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Palette.heading)
            Text(label.uppercased())
                .font(.system(.caption2, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Palette.text2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10)
        .padding(.top, 15)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// How it works: four numbered steps joined by a gold line.
private struct Timeline: View {
    private let steps: [(title: String, text: String)] = [
        ("Tell us the basics", "Purchase or refinance, who you are, and the property. About three minutes."),
        ("Send documents securely", "Your Purchase Contract or 1003 goes straight to our encrypted document portal."),
        ("We assign your officer", "Our team reviews the request and matches it with the right escrow officer."),
        ("Escrow is opened", "You receive your escrow number and your officer's direct contact information.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(index)
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let isLast = index == steps.count - 1
        let fade = Double(index) * 0.25
        return HStack(alignment: .top, spacing: 15) {
            VStack(spacing: 0) {
                Text("\(index + 1)")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Brand.gold2)
                    .frame(width: 36, height: 36)
                    .background(Palette.tile, in: Circle())
                if !isLast {
                    LinearGradient(colors: [Brand.gold.opacity(1 - fade), Brand.gold.opacity(0.75 - fade)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(steps[index].title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.heading)
                Text(steps[index].text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 18 : 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}
