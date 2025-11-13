import Foundation

/// 飛劍配置使用範例
/// 展示如何在不同場景中使用不同的配置
struct FlyingSwordConfigExample {

    // MARK: - 基本使用

    /// 使用標準配置創建飛劍組件
    static func createStandardSword() -> FlyingSwordComponent {
        return FlyingSwordComponent(config: .standard)
    }

    /// 使用輕劍配置創建飛劍組件
    static func createLightSword() -> FlyingSwordComponent {
        return FlyingSwordComponent(config: .lightSword)
    }

    /// 使用重劍配置創建飛劍組件
    static func createHeavySword() -> FlyingSwordComponent {
        return FlyingSwordComponent(config: .heavySword)
    }

    /// 使用平衡配置創建飛劍組件
    static func createBalancedSword() -> FlyingSwordComponent {
        return FlyingSwordComponent(config: .balanced)
    }

    // MARK: - 自訂配置

    /// 創建自訂配置的飛劍（極速劍）
    static func createSpeedSword() -> FlyingSwordComponent {
        var config = FlyingSwordConfig.standard

        // 調整參數使劍更快更靈活
        config.velocityMultiplier = 3.0      // 更高的速度倍數
        config.velocityThreshold = 0.15      // 更容易觸發
        config.dragCoefficient = 0.0         // 無阻力
        config.remoteControlStrength = 2.0   // 超強遙控
        config.maxVelocityChange = 25.0      // 允許更劇烈的變化

        return FlyingSwordComponent(config: config)
    }

    /// 創建自訂配置的飛劍（控制劍）
    static func createControlSword() -> FlyingSwordComponent {
        var config = FlyingSwordConfig.standard

        // 調整參數使劍更易控制
        config.velocityMultiplier = 1.5      // 較慢速度
        config.velocityThreshold = 0.25      // 需要更大力道
        config.remoteControlStrength = 1.8   // 強遙控
        config.fingerInfluenceRatio = 3.5    // 高手指影響
        config.maxFlyingTime = 15.0          // 更長飛行時間

        return FlyingSwordComponent(config: config)
    }

    /// 創建物理真實的飛劍配置
    static func createRealisticSword() -> FlyingSwordComponent {
        var config = FlyingSwordConfig.standard

        // 啟用完整物理效果
        config.dragCoefficient = 0.3         // 空氣阻力
        config.gravity = -9.8                // 完整重力
        config.gravityFactor = 0.01           // 100% 重力影響
        config.remoteControlStrength = 0.0   // 無遙控（純物理）

        return FlyingSwordComponent(config: config)
    }

    // MARK: - 運行時調整配置

    /// 在運行時調整飛劍配置的範例
    static func adjustSwordConfigAtRuntime(component: inout FlyingSwordComponent) {
        // 增加速度
        component.config.velocityMultiplier *= 1.2

        // 減少重力影響
        component.config.gravityFactor *= 0.8

        // 調整遙控強度
        component.config.remoteControlStrength = 1.5

        print("⚙️ 飛劍配置已調整")
    }

    /// 根據遊戲難度調整配置
    static func adjustForDifficulty(difficulty: GameDifficulty) -> FlyingSwordComponent {
        var config = FlyingSwordConfig.standard

        switch difficulty {
        case .easy:
            // 簡單模式：高控制力，易觸發
            config.velocityThreshold = 0.15
            config.remoteControlStrength = 2.0
            config.maxFlyingTime = 15.0
            config.dragCoefficient = 0.0

        case .normal:
            // 標準模式：使用預設值
            config = .balanced

        case .hard:
            // 困難模式：低控制力，物理真實
            config.velocityThreshold = 0.3
            config.remoteControlStrength = 0.5
            config.maxFlyingTime = 5.0
            config.dragCoefficient = 0.5
            config.gravity = -9.8
            config.gravityFactor = 1.0
        }

        return FlyingSwordComponent(config: config)
    }

    // MARK: - 配置比較

    /// 列印配置詳情（用於調試）
    static func printConfigDetails(config: FlyingSwordConfig, name: String) {
        print("""

        === \(name) ===
        重量: \(config.swordWeight) kg
        長度: \(config.swordLength) m
        速度閾值: \(config.velocityThreshold) m/s
        速度倍數: \(config.velocityMultiplier)x
        阻力係數: \(config.dragCoefficient)
        重力: \(config.gravity) m/s²
        重力影響: \(config.gravityFactor * 100)%
        遙控強度: \(config.remoteControlStrength)
        手指影響: \(config.fingerInfluenceRatio)
        最大飛行時間: \(config.maxFlyingTime) 秒
        跟隨偏移: \(config.followOffset) m

        """)
    }

    /// 比較所有預設配置
    static func compareAllPresets() {
        printConfigDetails(config: .standard, name: "標準劍")
        printConfigDetails(config: .lightSword, name: "輕劍")
        printConfigDetails(config: .heavySword, name: "重劍")
        printConfigDetails(config: .balanced, name: "平衡劍")
    }
}

// MARK: - 遊戲難度枚舉

enum GameDifficulty {
    case easy
    case normal
    case hard
}

// MARK: - 在 HandTrackingSystem 中的使用範例

/*
 在 HandTrackingSystem.swift 的 addJoints 函數中：

 // 標準配置
 sword.components.set(FlyingSwordComponent(config: .standard))

 // 輕劍配置
 sword.components.set(FlyingSwordComponent(config: .lightSword))

 // 自訂配置
 var customConfig = FlyingSwordConfig.standard
 customConfig.velocityMultiplier = 2.5
 customConfig.remoteControlStrength = 1.5
 sword.components.set(FlyingSwordComponent(config: customConfig))

 // 使用便利方法
 sword.components.set(FlyingSwordConfigExample.createSpeedSword())
 */
