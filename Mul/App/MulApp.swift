import SwiftUI

@main
struct HandTracking: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }

        // The immersive space that defines `HandPositionView`.
        ImmersiveSpace(id: "HandTrackingScene") {
            HandTrackingView()
        }
    }
}



