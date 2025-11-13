import SwiftUI
import RealityKit
import RealityKitContent
import simd

struct ContentView: View {
    @State private var immersionStyle: ImmersionStyle = .mixed
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isImmersiveSpaceOpen = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🗡️ 飛劍控制")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("進入沉浸式模式，讓飛劍在真實世界中飛行")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                if !isImmersiveSpaceOpen {
                    Button("啟動飛劍") {
                        Task {
                            await openImmersiveSpace(id: "FlyingSwordSpace")
                            isImmersiveSpaceOpen = true
                        }
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                } else {
                    VStack(spacing: 15) {
                        Text("🚀 飛劍已啟動")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("使用手勢來控制飛劍：")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "hand.tap")
                                Text("點擊空中任意位置移動飛劍")
                            }
                            HStack {
                                Image(systemName: "hand.draw")
                                Text("拖拽來讓飛劍跟隨您的手")
                            }
                        }
                        .font(.body)
                        
                        Button("停止飛劍") {
                            Task {
                                await dismissImmersiveSpace()
                                isImmersiveSpaceOpen = false
                            }
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: 600)
    }
}

// 沉浸式飛劍視圖
struct FlyingSwordImmersiveView: View {
    @State private var targetPosition: SIMD3<Float> = SIMD3<Float>(0, 1.5, -2.0)
    @State private var currentPosition: SIMD3<Float> = SIMD3<Float>(0, 1.5, -2.0)
    @State private var speed: Float = 5.0
    @State private var showControls = true
    @State private var lastUpdateTime = Date()
    private let swordName = "FlyingSword"

    var body: some View {
        RealityView { content in
            await loadSwordEntity(into: content)
            print("🔧 RealityView 初始化完成")
        } update: { content in
            updateSwordMovement(in: content)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let location = value.location3D
                    updateTargetFromTouch(location)
                }
        )
        .onTapGesture { location in
            print("🎯 點擊位置: \(location)")
            // 簡化的點擊處理
            let newTarget = SIMD3<Float>(
                Float(location.x - 200) * 0.01, // 轉換螢幕座標
                Float(200 - location.y) * 0.01 + 1.5,
                -2.0
            )
            targetPosition = newTarget
            print("🎯 新目標位置: \(targetPosition)")
        }
        .onTapGesture(count: 2) {
            showControls.toggle()
            print("🎛️ 控制面板切換: \(showControls)")
        }
        .overlay(alignment: .bottomTrailing) {
            if showControls {
                controlPanel
            }
        }
        .overlay(alignment: .topLeading) {
            statusPanel
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            Text("飛劍控制")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("速度")
                Spacer()
                Text("\(String(format: "%.1f", speed)) m/s")
                    .fontWeight(.semibold)
            }
            
            Slider(value: $speed, in: 1.0...20.0, step: 1.0)
            
            Button("重置位置") {
                resetSwordPosition()
            }
            .buttonStyle(.borderedProminent)
            
            Button("測試移動") {
                testMovement()
            }
            .buttonStyle(.bordered)
            
            Text("單擊移動，雙擊隱藏")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(width: 280)
        .padding()
    }
    
    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🗡️ 飛劍狀態")
                .font(.headline)
            Text("當前: (\(String(format: "%.1f", currentPosition.x)), \(String(format: "%.1f", currentPosition.y)), \(String(format: "%.1f", currentPosition.z)))")
            Text("目標: (\(String(format: "%.1f", targetPosition.x)), \(String(format: "%.1f", targetPosition.y)), \(String(format: "%.1f", targetPosition.z)))")
            Text("速度: \(String(format: "%.1f", speed)) m/s")
            Text("距離: \(String(format: "%.2f", simd_distance(currentPosition, targetPosition))) m")
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .font(.caption)
        .padding()
    }
    
    private func resetSwordPosition() {
        targetPosition = SIMD3<Float>(0, 1.5, -2.0)
        currentPosition = targetPosition
        print("🔄 重置飛劍位置")
    }
    
    private func testMovement() {
        let randomX = Float.random(in: -2.0...2.0)
        let randomY = Float.random(in: 1.0...2.5)
        targetPosition = SIMD3<Float>(randomX, randomY, -2.0)
        print("🧪 測試移動到: \(targetPosition)")
    }
    
    private func updateTargetFromTouch(_ location: Point3D) {
        let newTarget = SIMD3<Float>(
            Float(location.x) * 0.005, // 更細緻的轉換
            Float(location.y) * 0.005 + 1.5,
            Float(location.z) - 2.0
        )
        targetPosition = newTarget
        print("👆 拖拽目標: \(targetPosition)")
    }
    
    @MainActor
    private func loadSwordEntity(into content: RealityViewContent) async {
        print("🔧 開始載入飛劍模型...")
        
        // 直接創建備用模型，確保一定有東西顯示
        let swordShape = createVisibleSword()
        swordShape.name = swordName
        swordShape.position = currentPosition
        content.add(swordShape)
        print("✅ 飛劍模型載入完成，位置: \(currentPosition)")
    }
    
    private func createVisibleSword() -> Entity {
        let swordEntity = Entity()
        
        // 創建一個大一些、更顯眼的劍
        let handle = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.1, 0.1, 0.5)),
            materials: [SimpleMaterial(color: UIColor.systemRed, isMetallic: false)]
        )
        handle.position = SIMD3<Float>(0, 0, -0.25)
        
        let blade = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.05, 0.2, 1.0)),
            materials: [UnlitMaterial(color: UIColor.cyan)]
        )
        blade.position = SIMD3<Float>(0, 0, 0.5)
        
        let crossguard = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.5, 0.05, 0.1)),
            materials: [SimpleMaterial(color: UIColor.systemYellow, isMetallic: true)]
        )
        crossguard.position = SIMD3<Float>(0, 0, 0)
        
        // 添加一個明顯的發光球
        let glowOrb = ModelEntity(
            mesh: .generateSphere(radius: 0.05),
            materials: [UnlitMaterial(color: UIColor.white)]
        )
        glowOrb.position = SIMD3<Float>(0, 0, 1.0)
        
        swordEntity.addChild(handle)
        swordEntity.addChild(blade)
        swordEntity.addChild(crossguard)
        swordEntity.addChild(glowOrb)
        
        print("🗡️ 創建了可見的備用劍模型")
        return swordEntity
    }
    
    private func updateSwordMovement(in content: RealityViewContent) {
        guard let sword = content.entities.first(where: { $0.name == swordName }) else {
            print("❌ 找不到飛劍實體")
            return
        }
        
        let now = Date()
        let deltaTime = Float(now.timeIntervalSince(lastUpdateTime))
        lastUpdateTime = now
        
        currentPosition = sword.position
        let direction = targetPosition - currentPosition
        let distance = simd_length(direction)
        
        if distance > 0.1 { // 只有當距離足夠大時才移動
            let moveSpeed = speed * deltaTime
            let moveDistance = min(distance, moveSpeed)
            let normalizedDirection = simd_normalize(direction)
            
            let newPosition = currentPosition + normalizedDirection * moveDistance
            sword.position = newPosition
            currentPosition = newPosition
            
            // 更新方向
            let forward = SIMD3<Float>(0, 0, 1)
            let rotation = simd_quatf(from: forward, to: normalizedDirection)
            sword.orientation = rotation
            
            print("🚀 飛劍移動: \(currentPosition) -> \(targetPosition), 距離: \(distance)")
        }
    }
}