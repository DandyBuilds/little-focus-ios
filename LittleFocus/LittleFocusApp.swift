import SwiftUI

@main
struct LittleFocusApp: App {
    @StateObject private var model = FocusModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .tint(Color(red: 0.80, green: 0.90, blue: 0.64))
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.tick() }
                    else { model.save() }
                }
        }
    }
}
