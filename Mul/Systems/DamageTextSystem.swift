import RealityKit
import SwiftUI

/// 傷害數字顯示工具
enum DamageTextSystem {

    /// 在敵人頭上顯示傷害數字
    /// - Parameters:
    ///   - damage: 傷害值
    ///   - enemyEntity: 敵人實體
    @MainActor
    static func showDamageText(damage: Float, on enemyEntity: Entity) {
        // 創建文字內容
        let damageText = String(format: "%.0f", damage)

        // 創建 3D 文字實體
        let textMesh = MeshResource.generateText(
            damageText,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.3, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        // 創建材質（紅色發光）
        var material = UnlitMaterial()
        material.color = .init(tint: .red)

        let textEntity = ModelEntity(mesh: textMesh, materials: [material])

        // 計算位置：敵人頭頂上方 0.5 米
        // 敵人高度約 1.25m，中心點在 -0.475m，頭頂約在 0.15m
        textEntity.position = [0, 0.65, 0]  // 相對於敵人中心

        // 讓文字始終面向攝影機（billboard 效果）
        textEntity.look(at: [0, 0.65, -1], from: textEntity.position, relativeTo: enemyEntity)

        // 添加到敵人實體
        enemyEntity.addChild(textEntity)

        // 動畫：向上飄 + 淡出
        Task {
            let animationDuration: TimeInterval = 1.5
            let startTime = Date()

            while Date().timeIntervalSince(startTime) < animationDuration {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = Float(elapsed / animationDuration)

                // 向上飄動
                textEntity.position.y = 0.65 + progress * 0.5

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
