import SwiftUI

@main
struct OrbitApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 860, minHeight: 560)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1060, height: 720)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
