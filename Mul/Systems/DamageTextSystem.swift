import RealityKit
import SwiftUI

/// 傷害數字顯示工具
enum DamageTextSystem {

    /// 當前使用的配置
    static var config: DamageTextConfig = .default

    /// 上次顯示傷害的時間
    private static var lastDisplayTime: Date?

    /// 上次計算出的實際顯示間隔（根據飛劍速度動態調整）
    private static var lastCalculatedInterval: TimeInterval = 0.1

    /// 待顯示的傷害隊列
    private static var damageQueue: [(damage: Float, position: SIMD3<Float>, fingerPos: SIMD3<Float>?, root: Entity, swordSpeed: Float)] = []

    /// 隊列處理任務（只啟動一次）
    private static var queueTask: Task<Void, Never>?

    /// 在指定世界位置顯示傷害數字（不綁定到敵人）
    /// - Parameters:
    ///   - damage: 傷害值
    ///   - worldPosition: 世界坐標位置
    ///   - playerFingerPosition: 玩家手指位置（用於計算朝向）
    ///   - sceneRoot: 場景根實體
    ///   - swordSpeed: 飛劍速度（m/s），用於動態調整顯示效果
    @MainActor
    static func showDamageText(damage: Float, at worldPosition: SIMD3<Float>, playerFingerPosition: SIMD3<Float>?, sceneRoot: Entity?, swordSpeed: Float = 0) {
        print("💥 DamageTextSystem: 收到傷害數字請求 \(damage)")

        guard let root = sceneRoot else {
            print("❌ DamageTextSystem: 場景根實體為 nil")
            return
        }

        // 檢查是否需要延遲顯示
        let now = Date()
        let shouldDelay: Bool

        if let lastTime = lastDisplayTime {
            let timeSinceLastDisplay = now.timeIntervalSince(lastTime)
            // 使用上次計算的間隔時間來判斷是否需要延遲
            shouldDelay = timeSinceLastDisplay < lastCalculatedInterval
        } else {
            // 第一次顯示，不延遲
            shouldDelay = false
        }

        if shouldDelay {
            // 加入隊列，延遲顯示
            damageQueue.append((damage: damage, position: worldPosition, fingerPos: playerFingerPosition, root: root, swordSpeed: swordSpeed))
            print("   ⏳ 傷害加入隊列（隊列長度: \(damageQueue.count)）")

            // 確保隊列處理任務正在運行
            startQueueProcessorIfNeeded()
        } else {
            // 立即顯示（第一次或已超過間隔時間）
            // 計算這次顯示的實際間隔時間
            let actualInterval = calculateDisplayInterval(swordSpeed: swordSpeed)
            lastCalculatedInterval = actualInterval
            lastDisplayTime = now
            displayDamageTextImmediately(damage: damage, at: worldPosition, playerFingerPosition: playerFingerPosition, sceneRoot: root, swordSpeed: swordSpeed)
        }
    }

    /// 根據飛劍速度計算顯示間隔時間
    /// - Parameter swordSpeed: 飛劍速度（m/s）
    /// - Returns: 實際的顯示間隔時間（秒）
    private static func calculateDisplayInterval(swordSpeed: Float) -> TimeInterval {
        // 計算間隔縮減比例
        let intervalReduction = config.speedInfluenceOnInterval * swordSpeed
        // 計算實際間隔（最小 0.05 秒）
        let actualInterval = max(0.05, config.baseDisplayInterval * TimeInterval(1.0 - intervalReduction))
        return actualInterval
    }

    /// 啟動隊列處理任務（如果尚未啟動）
    @MainActor
    private static func startQueueProcessorIfNeeded() {
        guard queueTask == nil else { return }

        queueTask = Task {
            while true {
                // 每 0.05 秒檢查一次隊列
                try? await Task.sleep(for: .milliseconds(50))

                guard !damageQueue.isEmpty else {
                    // 隊列為空，結束任務
                    queueTask = nil
                    return
                }

                // 檢查是否可以顯示下一個傷害
                let now = Date()
                if let lastTime = lastDisplayTime {
                    let timeSinceLastDisplay = now.timeIntervalSince(lastTime)
                    // 使用上次計算的間隔時間來判斷
                    if timeSinceLastDisplay >= lastCalculatedInterval {
                        // 可以顯示下一個
                        let nextDamage = damageQueue.removeFirst()

                        // 根據下一個傷害的飛劍速度計算新的間隔時間
                        let newInterval = calculateDisplayInterval(swordSpeed: nextDamage.swordSpeed)
                        lastCalculatedInterval = newInterval
                        lastDisplayTime = now

                        displayDamageTextImmediately(
                            damage: nextDamage.damage,
                            at: nextDamage.position,
                            playerFingerPosition: nextDamage.fingerPos,
                            sceneRoot: nextDamage.root,
                            swordSpeed: nextDamage.swordSpeed
                        )
                    }
                } else {
                    // 沒有上次顯示時間，立即顯示（這個分支理論上不會執行，因為第一次已經在外面處理了）
                    let nextDamage = damageQueue.removeFirst()
                    let newInterval = calculateDisplayInterval(swordSpeed: nextDamage.swordSpeed)
                    lastCalculatedInterval = newInterval
                    lastDisplayTime = now

                    displayDamageTextImmediately(
                        damage: nextDamage.damage,
                        at: nextDamage.position,
                        playerFingerPosition: nextDamage.fingerPos,
                        sceneRoot: nextDamage.root,
                        swordSpeed: nextDamage.swordSpeed
                    )
                }
            }
        }
    }

    /// 立即顯示傷害數字（內部實現）
    @MainActor
    private static func displayDamageTextImmediately(damage: Float, at worldPosition: SIMD3<Float>, playerFingerPosition: SIMD3<Float>?, sceneRoot: Entity?, swordSpeed: Float = 0) {
        print("   ✅ 立即顯示傷害數字 \(damage) 於位置 \(worldPosition)，飛劍速度: \(String(format: "%.2f", swordSpeed)) m/s")

        guard let root = sceneRoot else {
            return
        }

        // 根據飛劍速度調整顯示參數
        let speedMultiplier = swordSpeed

        // 計算實際的飄動速度（基礎速度 + 速度影響）
        let actualFloatSpeed = config.floatSpeed * (1.0 + config.speedInfluenceOnFloatSpeed * speedMultiplier)

        // 計算實際的持續時間（基礎時間 - 速度影響，但不會低於0.5秒）
        let durationReduction = config.speedInfluenceOnDuration * speedMultiplier
        let actualDuration = max(0.5, config.fadeDuration * TimeInterval(1.0 - durationReduction))

        // 計算下一次的顯示間隔
        let nextInterval = lastCalculatedInterval

        print("   📊 顯示參數: 飄動速度=\(String(format: "%.2f", actualFloatSpeed)) m/s, 持續時間=\(String(format: "%.2f", actualDuration))s, 下次間隔=\(String(format: "%.3f", nextInterval))s")

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

        // 動畫：向上飄 + 淡出（使用計算後的實際參數）
        Task {
            let animationDuration = actualDuration
            let startTime = Date()
            let startY = textEntity.position.y

            while Date().timeIntervalSince(startTime) < animationDuration {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = Float(elapsed / animationDuration)

                // 向上飄動（使用計算後的實際飄動速度）
                let floatDistance = actualFloatSpeed * Float(elapsed)
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
