import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            RequestsView()
                .tabItem { Label("Requests", systemImage: "doc.text") }
                .tag(AppTab.requests)
            ContactView()
                .tabItem { Label("Contact", systemImage: "phone") }
                .tag(AppTab.contact)
            HelpView()
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
                .tag(AppTab.help)
        }
        .sheet(item: $app.activeIntake, onDismiss: nil) { model in
            IntakeSheet(model: model)
                .onDisappear { app.intakeClosed(model) }
        }
        .confirmationDialog("You have a request in progress.", isPresented: $app.showDraftChoice, titleVisibility: .visible) {
            Button("Resume my draft") { app.resumeDraft() }
            Button("Start a new request", role: .destructive) { app.startNewDiscardingDraft() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It's saved on this iPhone. Starting a new one deletes it.")
        }
    }
}
