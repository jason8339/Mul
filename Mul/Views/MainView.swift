import SwiftUI
import RealityKit

struct MainView: View {
    // 開啟/關閉沉浸式空間的環境動作
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    // 追蹤沉浸式空間是否已開啟（僅用於 UI 與避免重複動作）
    @State private var isImmersiveSpaceOpen = false
    @State private var isOpeningOrClosing = false

    // 若你仍然需要在這裡註冊系統，可保留這兩個旗標；建議改為在 HandTrackingView 註冊
    private static var didRegisterHandTrackingSystem = false
    private static var didRegisterFlyingSwordSystem = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Hand Tracking Example")

            HStack {
                Button {
                    Task {
                        guard !isOpeningOrClosing, !isImmersiveSpaceOpen else { return }
                        isOpeningOrClosing = true
                        let result = await openImmersiveSpace(id: "HandTrackingScene")
                        switch result {
                        case .opened:
                            isImmersiveSpaceOpen = true
                            print("✅ Immersive space opened successfully.")

                            // 如果你仍想在這裡註冊系統（不建議；建議移到 HandTrackingView）
                            if !Self.didRegisterHandTrackingSystem {
                                HandTrackingSystem.registerSystem()
                                Self.didRegisterHandTrackingSystem = true
                                print("✅ HandTrackingSystem registered.")
                            }
                            if !Self.didRegisterFlyingSwordSystem {
                                FlyingSwordSystem.registerSystem()
                                Self.didRegisterFlyingSwordSystem = true
                                print("✅ FlyingSwordSystem registered.")
                            }

                        case .userCancelled:
                            print("🚫 User cancelled opening immersive space.")
                        case .error:
                            print("❌ Failed to open immersive space.")
                        @unknown default:
                            print("⚠️ Unknown immersive space result.")
                        }
                        isOpeningOrClosing = false
                    }
                } label: {
                    Text("開啟 Immersive Space")
                }
                .disabled(isImmersiveSpaceOpen || isOpeningOrClosing)

                Button(role: .destructive) {
                    Task {
                        guard !isOpeningOrClosing, isImmersiveSpaceOpen else { return }
                        isOpeningOrClosing = true
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                        isOpeningOrClosing = false
                        print("✅ Immersive space closed.")
                    }
                } label: {
                    Text("關閉 Immersive Space")
                }
                .disabled(!isImmersiveSpaceOpen || isOpeningOrClosing)
            }
        }
        // 當 MainView 消失時，確保關閉 ImmersiveSpace（1. 自動關閉）
        .onDisappear {
            Task {
                if isImmersiveSpaceOpen {
                    await dismissImmersiveSpace()
                    isImmersiveSpaceOpen = false
                    print("✅ Immersive space closed on view disappear.")
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    MainView()
}
