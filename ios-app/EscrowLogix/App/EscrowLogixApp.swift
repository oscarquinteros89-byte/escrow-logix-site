import SwiftUI

@main
struct EscrowLogixApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(app.requests)
                .tint(Palette.accent)
                .onOpenURL { app.handle($0) }
        }
    }
}
