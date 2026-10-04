import SwiftUI

/// Contact: call the office, directions, hours, Save to Contacts, and the team.
struct ContactView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var web: WebLink?
    @State private var savingContact = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        officeCard

                        VStack(spacing: 0) {
                            ListRow(icon: "mappin.and.ellipse", title: Office.street,
                                    subtitle: "\(Office.cityLine) · Directions") {
                                openURL(Office.directionsURL)
                            }
                            RowDivider(inset: 61)
                            ListRow(icon: "clock", title: Office.hours,
                                    subtitle: "After hours? Ask the 24/7 Assistant") {
                                web = WebLink(url: Office.assistant)
                            }
                            RowDivider(inset: 61)
                            ListRow(icon: "person.crop.circle.badge.plus", title: "Save to Contacts",
                                    subtitle: "Keep our verified number handy") {
                                savingContact = true
                            }
                        }
                        .card()
                        .padding(.top, 14)

                        teamBand
                            .padding(.top, 28)
                            .id("team")

                        SectionLabel("The Escrow Logix team")
                            .padding(.top, 22)
                        VStack(spacing: 0) {
                            ForEach(Array(Office.team.enumerated()), id: \.element.id) { index, member in
                                if index > 0 { RowDivider(inset: 75) }
                                MemberRow(member: member)
                            }
                        }
                        .card()

                        VStack(spacing: 0) {
                            ListRow(icon: "building.2", title: "Services") {
                                web = WebLink(url: Office.services)
                            }
                            RowDivider(inset: 61)
                            ListRow(icon: "person.3", title: "About & team") {
                                web = WebLink(url: Office.about)
                            }
                            RowDivider(inset: 61)
                            ListRow(icon: "globe", title: "escrowlogix.com") {
                                web = WebLink(url: Office.website)
                            }
                        }
                        .card()
                        .padding(.top, 24)
                        FootNote("Fax \(Office.faxDisplay). Licensed & bonded independent escrow company in California.")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .background(Palette.bg)
                .navigationTitle("Contact")
                .onAppear { scroll(proxy) }
                .onChange(of: app.scrollAnchor) { _, _ in scroll(proxy) }
            }
        }
        .sheet(item: $web) { link in
            SafariView(url: link.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $savingContact) {
            NewContactView { savingContact = false }
                .ignoresSafeArea()
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        guard app.scrollAnchor == "team" else { return }
        app.scrollAnchor = nil
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.smooth(duration: 0.5)) {
                proxy.scrollTo("team", anchor: .top)
            }
        }
    }

    // MARK: Office card

    private var officeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 178)
                .overlay {
                    Image("ContactPortrait")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                TimelineView(.everyMinute) { context in
                    let status = OfficeHours.status(at: context.date)
                    StatusPill(text: status.text, tint: status.isOpen ? Palette.success : Palette.accent)
                }
                Text("Prefer to talk it through?")
                    .font(.cardTitle)
                    .foregroundStyle(Palette.heading)
                    .padding(.top, 10)
                Text("Call the office and a member of our team will help you get your escrow started.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
                CallButton(location: "contact card") {
                    Label("Call \(Office.phoneDisplay)", systemImage: "phone.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 14)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .card()
    }

    // MARK: Team band

    private var teamBand: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 200)
                .overlay {
                    Image("TeamGroup")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityLabel("The Escrow Logix team")

            VStack(alignment: .leading, spacing: 6) {
                Kicker("Real people. Real accountability.", color: Color(hex: 0xDEC38E))
                Text("People who treat your transaction like their own.")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A dedicated escrow officer on every file, real-time status updates at each milestone, and a real person reviewing every request before your escrow is opened.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: 0xC8C5BE))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                Button {
                    web = WebLink(url: Office.reviews)
                } label: {
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(Brand.gold)
                        Text("5.0 on Google Reviews")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.goldLight)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Brand.goldLight)
                    }
                    .frame(minHeight: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("5.0 on Google Reviews")
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(Brand.charcoal)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .environment(\.colorScheme, .dark)
    }
}

/// One person on the team, with a round headshot.
private struct MemberRow: View {
    let member: TeamMember

    var body: some View {
        HStack(spacing: 13) {
            Headshot(photo: member.photo, name: member.name, size: 46)
            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.heading)
                Text(member.title)
                    .font(.footnote)
                    .foregroundStyle(Palette.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}
