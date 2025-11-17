import RealityKit
import SwiftUI

/// 傷害數字顯示工具
enum DamageTextSystem {

    /// 當前使用的配置
    static var config: DamageTextConfig = .default

    /// 在指定世界位置顯示傷害數字（不綁定到敵人）
    /// - Parameters:
    ///   - damage: 傷害值
    ///   - worldPosition: 世界坐標位置
    ///   - playerFingerPosition: 玩家手指位置（用於計算朝向）
    ///   - sceneRoot: 場景根實體
    @MainActor
    static func showDamageText(damage: Float, at worldPosition: SIMD3<Float>, playerFingerPosition: SIMD3<Float>?, sceneRoot: Entity?) {
        print("💥 DamageTextSystem: 在世界位置 \(worldPosition) 顯示傷害數字 \(damage)")

        guard let root = sceneRoot else {
            print("❌ DamageTextSystem: 場景根實體為 nil")
            return
        }

        // 創建文字內容
        let damageText = String(format: "%.0f", damage)

        // 創建 3D 文字實體（使用配置的大小）
        let textMesh = MeshResource.generateText(
            damageText,
            extrusionDepth: config.extrusionDepth,
            font: .systemFont(ofSize: CGFloat(config.fontSize), weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        // 創建材質（紅色發光）
        var material = UnlitMaterial()
        material.color = .init(tint: .red)

        let textEntity = ModelEntity(mesh: textMesh, materials: [material])

        // 設置世界坐標位置（加上初始偏移）
        textEntity.position = SIMD3<Float>(
            worldPosition.x,
            worldPosition.y + config.initialOffsetY,  // 使用配置的初始偏移
            worldPosition.z
        )

        // 讓文字面向玩家手指
        if let fingerPos = playerFingerPosition {
            // 計算從傷害位置指向手指的方向
            let directionToFinger = fingerPos - worldPosition

            // 只使用水平方向（XZ平面），保持文字直立
            let horizontalDirection = SIMD3<Float>(directionToFinger.x, 0, directionToFinger.z)

            if length(horizontalDirection) > 0.01 {
                // 計算旋轉：讓文字的 -Z 軸（正面）朝向手指
                let forward = normalize(horizontalDirection)
                let up = SIMD3<Float>(0, 1, 0)
                let right = normalize(cross(up, forward))
                let newUp = cross(forward, right)

                let rotationMatrix = float3x3(right, newUp, forward)
                textEntity.orientation = simd_quatf(rotationMatrix)

                print("   文字朝向玩家手指: \(fingerPos)")
            }
        }

        // 添加到場景根實體
        root.addChild(textEntity)
        print("✅ DamageTextSystem: 傷害文字已添加到場景")
        print("   世界位置: \(worldPosition)")

        // 動畫：向上飄 + 淡出（使用配置）
        Task {
            let animationDuration = config.fadeDuration
            let startTime = Date()
            let startY = textEntity.position.y

            while Date().timeIntervalSince(startTime) < animationDuration {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = Float(elapsed / animationDuration)

                // 向上飄動（使用配置的飄動速度）
                let floatDistance = config.floatSpeed * Float(elapsed)
                textEntity.position.y = startY + floatDistance

                // 淡出效果（調整材質透明度）
                var fadeMaterial = UnlitMaterial()
                fadeMaterial.color = .init(tint: .red.withAlphaComponent(CGFloat(1.0 - progress)))
                textEntity.model?.materials = [fadeMaterial]

                // 等待下一幀
                try? await Task.sleep(for: .milliseconds(16))
            }

            // 動畫結束，移除文字
            textEntity.removeFromParent()
        }
    }
}
