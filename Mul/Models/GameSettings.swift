import SwiftUI

/// 遊戲設定管理器 - 使用 AppStorage 實現即時調整
/// 所有設定都會自動保存，重啟遊戲後保留
class GameSettings {
    static let shared = GameSettings()

    private init() {}

    // MARK: - 飛劍配置預設模板
    enum SwordPreset: String, CaseIterable {
        case standard = "標準"
        case light = "輕劍"
        case heavy = "重劍"
        case balanced = "平衡"
    }

    // MARK: - 飛劍手感參數
    @AppStorage("sword_velocityThreshold") var velocityThreshold: Double = 0.3
    @AppStorage("sword_velocityMultiplier") var velocityMultiplier: Double = 5.0
    @AppStorage("sword_minFlyingSpeed") var minFlyingSpeed: Double = 1.0
    @AppStorage("sword_followOffset") var followOffset: Double = 0.12
    @AppStorage("sword_launchCooldown") var launchCooldown: Double = 0.8

    // 遙控參數
    @AppStorage("sword_remoteControlStrength") var remoteControlStrength: Double = 1.2
    @AppStorage("sword_fingerInfluenceRatio") var fingerInfluenceRatio: Double = 2.5
    @AppStorage("sword_maxRemoteControlDistance") var maxRemoteControlDistance: Double = 100.0
    @AppStorage("sword_maxVelocityChange") var maxVelocityChange: Double = 5.0

    // 轉向參數
    @AppStorage("sword_recallTurnSpeed") var recallTurnSpeed: Double = 3.0
    @AppStorage("sword_launchTurnSpeed") var launchTurnSpeed: Double = 5.0
    @AppStorage("sword_launchTurnDuration") var launchTurnDuration: Double = 0.3
    @AppStorage("sword_autoReturnTurnSpeed") var autoReturnTurnSpeed: Double = 3.0

    // 召回參數
    @AppStorage("sword_recallSpeed") var recallSpeed: Double = 1.0
    @AppStorage("sword_maxRecallSpeed") var maxRecallSpeed: Double = 5.0
    @AppStorage("sword_maxRecallSpeedTime") var maxRecallSpeedTime: Double = 5.0

    // MARK: - 飛劍物理參數
    @AppStorage("sword_swordWeight") var swordWeight: Double = 1.0
    @AppStorage("sword_swordLength") var swordLength: Double = 0.8
    @AppStorage("sword_dragCoefficient") var dragCoefficient: Double = 0.0
    @AppStorage("sword_gravity") var gravity: Double = 0.0
    @AppStorage("sword_gravityFactor") var gravityFactor: Double = 0.3

    // 物理引擎參數
    @AppStorage("sword_staticFriction") var staticFriction: Double = 0.2
    @AppStorage("sword_dynamicFriction") var dynamicFriction: Double = 0.1
    @AppStorage("sword_restitution") var restitution: Double = 0.7

    // MARK: - 敵人參數
    @AppStorage("enemy_spawnInterval") var enemySpawnInterval: Double = 10.0
    @AppStorage("enemy_spawnAreaSize") var enemySpawnAreaSize: Double = 30.0
    @AppStorage("enemy_playerExclusionRadius") var enemyPlayerExclusionRadius: Double = 10.0
    @AppStorage("enemy_maxHealth") var enemyMaxHealth: Double = 100.0
    @AppStorage("enemy_moveSpeed") var enemyMoveSpeed: Double = 0.1
    @AppStorage("enemy_scale") var enemyScale: Double = 0.5
    @AppStorage("enemy_damageMultiplier") var enemyDamageMultiplier: Double = 10.0
    @AppStorage("enemy_collisionRadius") var enemyCollisionRadius: Double = 1.15

    // MARK: - 傷害顯示參數
    @AppStorage("damage_fontSize") var damageFontSize: Double = 0.5
    @AppStorage("damage_floatSpeed") var damageFloatSpeed: Double = 1.0
    @AppStorage("damage_fadeDuration") var damageFadeDuration: Double = 1.5
    @AppStorage("damage_initialOffsetY") var damageInitialOffsetY: Double = 0.0
    @AppStorage("damage_speedInfluenceOnFloatSpeed") var damageSpeedInfluenceOnFloatSpeed: Double = 0.8
    @AppStorage("damage_speedInfluenceOnDuration") var damageSpeedInfluenceOnDuration: Double = 0.5

    // MARK: - 調試選項
    @AppStorage("debug_showCollisionBox") var showCollisionBox: Bool = false
    @AppStorage("debug_enableLogs") var enableDebugLogs: Bool = false

    // MARK: - 預設模板應用
    func applySwordPreset(_ preset: SwordPreset) {
        switch preset {
        case .standard:
            applyStandardPreset()
        case .light:
            applyLightSwordPreset()
        case .heavy:
            applyHeavySwordPreset()
        case .balanced:
            applyBalancedPreset()
        }
    }

    private func applyStandardPreset() {
        velocityThreshold = 0.3
        velocityMultiplier = 10.0
        minFlyingSpeed = 2.0
        swordWeight = 1.0
        swordLength = 0.8
        gravityFactor = 0.3
        followOffset = 0.12
        launchCooldown = 0.8
        remoteControlStrength = 2.2
        fingerInfluenceRatio = 2.5
        recallTurnSpeed = 3.0
        launchTurnSpeed = 5.0
        launchTurnDuration = 0.3
        autoReturnTurnSpeed = 3.0
        recallSpeed = 1.0
        maxRecallSpeed = 5.0
        maxRecallSpeedTime = 5.0
    }

    private func applyLightSwordPreset() {
        velocityThreshold = 0.15
        velocityMultiplier = 2.5
        minFlyingSpeed = 1.0
        swordWeight = 0.3
        swordLength = 0.7
        gravityFactor = 0.3
        followOffset = 0.12
        launchCooldown = 0.6
        remoteControlStrength = 1.5
        fingerInfluenceRatio = 3.0
        recallTurnSpeed = 4.0
        launchTurnSpeed = 6.0
        launchTurnDuration = 0.25
        autoReturnTurnSpeed = 7.0
        recallSpeed = 1.0
        maxRecallSpeed = 5.0
        maxRecallSpeedTime = 5.0
    }

    private func applyHeavySwordPreset() {
        velocityThreshold = 0.3
        velocityMultiplier = 1.5
        minFlyingSpeed = 1.0
        swordWeight = 0.8
        swordLength = 1.0
        gravityFactor = 0.5
        followOffset = 0.12
        launchCooldown = 1.0
        remoteControlStrength = 0.8
        fingerInfluenceRatio = 1.5
        recallTurnSpeed = 2.0
        launchTurnSpeed = 4.0
        launchTurnDuration = 0.4
        autoReturnTurnSpeed = 7.0
        recallSpeed = 1.0
        maxRecallSpeed = 5.0
        maxRecallSpeedTime = 5.0
    }

    private func applyBalancedPreset() {
        velocityThreshold = 0.25
        velocityMultiplier = 3.5
        minFlyingSpeed = 1.0
        swordWeight = 0.6
        swordLength = 0.85
        gravityFactor = 0.35
        followOffset = 0.12
        launchCooldown = 0.7
        remoteControlStrength = 1.0
        fingerInfluenceRatio = 2.0
        recallTurnSpeed = 3.5
        launchTurnSpeed = 5.5
        launchTurnDuration = 0.3
        autoReturnTurnSpeed = 5.0
        recallSpeed = 1.0
        maxRecallSpeed = 5.0
        maxRecallSpeedTime = 5.0
    }

    // MARK: - 重置為預設值
    func resetToDefaults() {
        applyStandardPreset()

        // 敵人預設值
        enemySpawnInterval = 10.0
        enemySpawnAreaSize = 30.0
        enemyPlayerExclusionRadius = 10.0
        enemyMaxHealth = 100.0
        enemyMoveSpeed = 0.1
        enemyScale = 0.5
        enemyDamageMultiplier = 10.0
        enemyCollisionRadius = 1.15

        // 傷害顯示預設值
        damageFontSize = 0.5
        damageFloatSpeed = 1.0
        damageFadeDuration = 1.5
        damageInitialOffsetY = 0.0
        damageSpeedInfluenceOnFloatSpeed = 0.8
        damageSpeedInfluenceOnDuration = 0.5

        // 物理參數預設值
        dragCoefficient = 0.0
        gravity = 0.0
        staticFriction = 0.2
        dynamicFriction = 0.1
        restitution = 0.7

        // 調試選項
        showCollisionBox = false
        enableDebugLogs = false
    }

    // MARK: - 獲取當前配置（用於系統讀取）
    func getCurrentFlyingSwordConfig() -> FlyingSwordConfig {
        return FlyingSwordConfig(
            swordWeight: Float(swordWeight),
            swordLength: Float(swordLength),
            velocityThreshold: Float(velocityThreshold),
            velocityMultiplier: Float(velocityMultiplier),
            minFlyingSpeed: Float(minFlyingSpeed),
            maxFlyingTime: 10000.0, // 固定值
            dragCoefficient: Float(dragCoefficient),
            gravity: Float(gravity),
            gravityFactor: Float(gravityFactor),
            followOffset: Float(followOffset),
            maxHistoryCount: 30, // 固定值
            minSampleInterval: 1.0/60.0, // 固定值
            velocityWindow: 0.25, // 固定值
            minEffectiveWindow: 0.15, // 固定值
            minSamplesForLaunch: 5, // 固定值
            launchCooldown: TimeInterval(launchCooldown),
            remoteControlStrength: Float(remoteControlStrength),
            fingerInfluenceRatio: Float(fingerInfluenceRatio),
            maxRemoteControlDistance: Float(maxRemoteControlDistance),
            maxVelocityChange: Float(maxVelocityChange),
            maxFingerHistoryCount: 10, // 固定值
            minFingerSampleInterval: 1.0/30.0, // 固定值
            collisionDetectionDelay: 1.0, // 固定值
            autoReturnDistance: 0.05, // 固定值
            autoReturnDelay: 1.0, // 固定值
            pinchGestureThreshold: 0.02, // 固定值
            recallSpeed: Float(recallSpeed),
            maxRecallSpeed: Float(maxRecallSpeed),
            maxRecallSpeedTime: TimeInterval(maxRecallSpeedTime),
            recallTurnSpeed: Float(recallTurnSpeed),
            launchTurnSpeed: Float(launchTurnSpeed),
            launchTurnDuration: TimeInterval(launchTurnDuration),
            autoReturnTurnSpeed: Float(autoReturnTurnSpeed)
        )
    }
}
