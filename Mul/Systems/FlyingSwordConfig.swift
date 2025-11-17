import Foundation
import simd

/// 飛劍配置結構體 - 純數據容器，遵守 SRP
/// 負責集中管理所有可調參數
struct FlyingSwordConfig {

    // MARK: - 基本物理屬性

    /// 劍的重量（公斤）
    var swordWeight: Float

    /// 劍的長度（公尺）
    var swordLength: Float

    // MARK: - 速度與運動參數

    /// 速度閾值（米/秒），低於此值不觸發飛行
    var velocityThreshold: Float

    /// 速度放大倍數（增加投擲力度）
    var velocityMultiplier: Float

    /// 最小飛行速度（低於此速度停止飛行）
    var minFlyingSpeed: Float

    /// 最大飛行時間（秒）
    var maxFlyingTime: TimeInterval

    // MARK: - 物理效果參數

    /// 劍飛行時的阻力係數（0-1）
    var dragCoefficient: Float

    /// 重力加速度（m/s²）
    var gravity: Float

    /// 重力影響因子（0-1，0表示不受重力影響，1表示完全受重力影響）
    var gravityFactor: Float

    // MARK: - 手部追蹤參數

    /// 劍跟隨手指時的偏移距離（公尺）
    var followOffset: Float

    /// 保留位置樣本的最大數量
    var maxHistoryCount: Int

    /// 樣本間的最小間隔時間（秒）
    var minSampleInterval: TimeInterval

    /// 用於速度平滑化的時間窗口（秒）
    var velocityWindow: TimeInterval

    /// 計算速度所需的最小有效時間窗口
    var minEffectiveWindow: TimeInterval

    /// 評估發射所需的最小樣本數
    var minSamplesForLaunch: Int

    /// 發射後的冷卻時間（秒）
    var launchCooldown: TimeInterval

    // MARK: - 飛行中遙控參數

    /// 遙控影響強度（0-1，0表示不受影響，1表示完全跟隨）
    var remoteControlStrength: Float

    /// 手指移動對飛劍的影響比例
    var fingerInfluenceRatio: Float

    /// 遙控響應的最大距離（公尺）
    var maxRemoteControlDistance: Float

    /// 遙控時速度的最大變化量（m/s）
    var maxVelocityChange: Float

    /// 飛行中手指位置樣本的最大數量
    var maxFingerHistoryCount: Int

    /// 手指移動的最小間隔時間（秒）
    var minFingerSampleInterval: TimeInterval

    // MARK: - 碰撞檢測參數

    /// 碰撞檢測的延遲時間（秒）- 飛劍必須飛行超過此時間才會開始檢測碰撞
    var collisionDetectionDelay: TimeInterval

    // MARK: - 自動返回與召回參數

    /// 飛劍自動返回的距離閾值（公尺）- 當劍靠近右手指尖此距離內會自動回到跟隨模式
    var autoReturnDistance: Float

    /// 自動返回的延遲時間（秒）- 飛劍必須飛行超過此時間才會開始檢測自動返回
    var autoReturnDelay: TimeInterval

    /// 左手捏合手勢識別的距離閾值（公尺）- 食指和大拇指小於此距離視為捏合
    var pinchGestureThreshold: Float

    /// 召回時飛劍的初始速度（m/s）
    var recallSpeed: Float

    /// 召回時飛劍的最大速度（m/s）
    var maxRecallSpeed: Float

    /// 達到最大召回速度所需的按壓時間（秒）
    var maxRecallSpeedTime: TimeInterval

    /// 召回時的轉向速度（弧度/秒）- 控制飛劍轉向的快慢，值越大轉向越快
    var recallTurnSpeed: Float

    /// 發射時的轉向速度（弧度/秒）- 控制發射後初期方向調整的快慢
    var launchTurnSpeed: Float

    /// 發射轉向持續時間（秒）- 發射後多久內進行方向平滑調整
    var launchTurnDuration: TimeInterval

    /// 自動返回時的轉向速度（弧度/秒）- 控制自動返回時轉向的快慢
    var autoReturnTurnSpeed: Float

    // MARK: - 初始化方法

    /// 使用所有參數初始化
    init(
        swordWeight: Float,
        swordLength: Float,
        velocityThreshold: Float,
        velocityMultiplier: Float,
        minFlyingSpeed: Float,
        maxFlyingTime: TimeInterval,
        dragCoefficient: Float,
        gravity: Float,
        gravityFactor: Float,
        followOffset: Float,
        maxHistoryCount: Int,
        minSampleInterval: TimeInterval,
        velocityWindow: TimeInterval,
        minEffectiveWindow: TimeInterval,
        minSamplesForLaunch: Int,
        launchCooldown: TimeInterval,
        remoteControlStrength: Float,
        fingerInfluenceRatio: Float,
        maxRemoteControlDistance: Float,
        maxVelocityChange: Float,
        maxFingerHistoryCount: Int,
        minFingerSampleInterval: TimeInterval,
        collisionDetectionDelay: TimeInterval,
        autoReturnDistance: Float,
        autoReturnDelay: TimeInterval,
        pinchGestureThreshold: Float,
        recallSpeed: Float,
        maxRecallSpeed: Float,
        maxRecallSpeedTime: TimeInterval,
        recallTurnSpeed: Float,
        launchTurnSpeed: Float,
        launchTurnDuration: TimeInterval,
        autoReturnTurnSpeed: Float
    ) {
        self.swordWeight = swordWeight
        self.swordLength = swordLength
        self.velocityThreshold = velocityThreshold
        self.velocityMultiplier = velocityMultiplier
        self.minFlyingSpeed = minFlyingSpeed
        self.maxFlyingTime = maxFlyingTime
        self.dragCoefficient = dragCoefficient
        self.gravity = gravity
        self.gravityFactor = gravityFactor
        self.followOffset = followOffset
        self.maxHistoryCount = maxHistoryCount
        self.minSampleInterval = minSampleInterval
        self.velocityWindow = velocityWindow
        self.minEffectiveWindow = minEffectiveWindow
        self.minSamplesForLaunch = minSamplesForLaunch
        self.launchCooldown = launchCooldown
        self.remoteControlStrength = remoteControlStrength
        self.fingerInfluenceRatio = fingerInfluenceRatio
        self.maxRemoteControlDistance = maxRemoteControlDistance
        self.maxVelocityChange = maxVelocityChange
        self.maxFingerHistoryCount = maxFingerHistoryCount
        self.minFingerSampleInterval = minFingerSampleInterval
        self.collisionDetectionDelay = collisionDetectionDelay
        self.autoReturnDistance = autoReturnDistance
        self.autoReturnDelay = autoReturnDelay
        self.pinchGestureThreshold = pinchGestureThreshold
        self.recallSpeed = recallSpeed
        self.maxRecallSpeed = maxRecallSpeed
        self.maxRecallSpeedTime = maxRecallSpeedTime
        self.recallTurnSpeed = recallTurnSpeed
        self.launchTurnSpeed = launchTurnSpeed
        self.launchTurnDuration = launchTurnDuration
        self.autoReturnTurnSpeed = autoReturnTurnSpeed
    }
}

// MARK: - 預設配置

extension FlyingSwordConfig {

    /// 標準配置（原始設定值）
    static let standard = FlyingSwordConfig(
        swordWeight: 1,               // 1000克
        swordLength: 0.8,                // 80公分
        velocityThreshold: 0.3,          // 0.2 m/s
        velocityMultiplier: 5,         // 2倍速度
        minFlyingSpeed: 1,             // 0.1 m/s
        maxFlyingTime: 10000.0,              // 8秒
        dragCoefficient: 0.0,            // 無阻力
        gravity: 0.0,                    // 無重力
        gravityFactor: 0.3,              // 30%重力影響
        followOffset: 0.12,              // 12公分偏移
        maxHistoryCount: 30,             // 30個樣本
        minSampleInterval: 1.0 / 60.0,   // 60 FPS
        velocityWindow: 0.25,            // 0.25秒窗口
        minEffectiveWindow: 0.15,        // 0.15秒最小窗口
        minSamplesForLaunch: 5,          // 至少5個樣本
        launchCooldown: 0.8,             // 0.8秒冷卻
        remoteControlStrength: 1.2,      // 120%遙控強度
        fingerInfluenceRatio: 2.5,       // 2.5倍手指影響
        maxRemoteControlDistance: 100.0, // 100公尺最大距離
        maxVelocityChange: 5.0,         // 15 m/s 最大變化
        maxFingerHistoryCount: 10,       // 10個手指樣本
        minFingerSampleInterval: 1.0 / 30.0,  // 30 FPS
        collisionDetectionDelay: 1.0,    // 1秒後才開始碰撞檢測
        autoReturnDistance: 0.05,        // 5公分自動返回
        autoReturnDelay: 1.0,            // 1秒後才檢測自動返回
        pinchGestureThreshold: 0.02,     // 2公分捏合識別
        recallSpeed: 1,                // 0.5 m/s 召回初始速度
        maxRecallSpeed: 5.0,             // 3.0 m/s 召回最大速度
        maxRecallSpeedTime: 5.0,         // 6秒達到最大速度（0-3秒保持低速）
        recallTurnSpeed: 3.0,            // 3.0 弧度/秒 轉向速度
        launchTurnSpeed: 5.0,            // 5.0 弧度/秒 發射轉向速度
        launchTurnDuration: 0.3,         // 0.3秒 發射轉向持續時間
        autoReturnTurnSpeed:3.0         // 3.0 弧度/秒 自動返回轉向速度
    )

    /// 輕劍配置 - 快速靈活
    static let lightSword = FlyingSwordConfig(
        swordWeight: 0.3,                // 300克（輕）
        swordLength: 0.7,                // 70公分（短）
        velocityThreshold: 0.15,         // 更容易觸發
        velocityMultiplier: 2.5,         // 更快速度
        minFlyingSpeed: 0.08,
        maxFlyingTime: 10000.0,          // 10000秒
        dragCoefficient: 0.1,            // 輕微阻力
        gravity: -9.8,                   // 受重力影響
        gravityFactor: 0.2,              // 較少重力影響（輕）
        followOffset: 0.10,
        maxHistoryCount: 30,
        minSampleInterval: 1.0 / 60.0,
        velocityWindow: 0.25,
        minEffectiveWindow: 0.15,
        minSamplesForLaunch: 5,
        launchCooldown: 0.6,             // 更短冷卻
        remoteControlStrength: 1.5,      // 更強遙控（靈活）
        fingerInfluenceRatio: 3.0,       // 更大手指影響
        maxRemoteControlDistance: 120.0,
        maxVelocityChange: 5.0,          // 5 m/s 最大變化
        maxFingerHistoryCount: 10,
        minFingerSampleInterval: 1.0 / 30.0,
        collisionDetectionDelay: 1.0,    // 1秒後才開始碰撞檢測
        autoReturnDistance: 0.05,        // 5公分自動返回
        autoReturnDelay: 0.8,            // 0.8秒後檢測（更快響應）
        pinchGestureThreshold: 0.02,     // 2公分捏合識別
        recallSpeed: 1,                // 0.5 m/s 召回初始速度
        maxRecallSpeed: 3.0,             // 3.0 m/s 召回最大速度
        maxRecallSpeedTime: 6.0,         // 6秒達到最大速度（0-3秒保持低速）
        recallTurnSpeed: 4.0,            // 4.0 弧度/秒 轉向速度（更靈活）
        launchTurnSpeed: 6.0,            // 6.0 弧度/秒 發射轉向速度（更快）
        launchTurnDuration: 0.25,        // 0.25秒 發射轉向持續時間（更短）
        autoReturnTurnSpeed: 7.0         // 4.0 弧度/秒 自動返回轉向速度（更靈活）
    )

    /// 重劍配置 - 強力穩定
    static let heavySword = FlyingSwordConfig(
        swordWeight: 0.8,                // 800克（重）
        swordLength: 1.0,                // 100公分（長）
        velocityThreshold: 0.3,          // 需要更大力道
        velocityMultiplier: 1.5,         // 較慢速度
        minFlyingSpeed: 0.15,
        maxFlyingTime: 10000.0,          // 10000秒
        dragCoefficient: 0.0,            // 無阻力（慣性大）
        gravity: -9.8,
        gravityFactor: 0.5,              // 更多重力影響（重）
        followOffset: 0.15,
        maxHistoryCount: 30,
        minSampleInterval: 1.0 / 60.0,
        velocityWindow: 0.25,
        minEffectiveWindow: 0.15,
        minSamplesForLaunch: 5,
        launchCooldown: 1.0,             // 更長冷卻
        remoteControlStrength: 0.8,      // 較弱遙控（穩定）
        fingerInfluenceRatio: 1.5,       // 較小手指影響
        maxRemoteControlDistance: 80.0,
        maxVelocityChange: 5.0,          // 5 m/s 最大變化
        maxFingerHistoryCount: 10,
        minFingerSampleInterval: 1.0 / 30.0,
        collisionDetectionDelay: 1.0,    // 1秒後才開始碰撞檢測
        autoReturnDistance: 0.05,        // 5公分自動返回
        autoReturnDelay: 1.2,            // 1.2秒後檢測（更穩定）
        pinchGestureThreshold: 0.02,     // 2公分捏合識別
        recallSpeed: 1,                // 0.5 m/s 召回初始速度
        maxRecallSpeed: 3.0,             // 3.0 m/s 召回最大速度
        maxRecallSpeedTime: 6.0,         // 6秒達到最大速度（0-3秒保持低速）
        recallTurnSpeed: 2.0,            // 2.0 弧度/秒 轉向速度（更穩定）
        launchTurnSpeed: 4.0,            // 4.0 弧度/秒 發射轉向速度（較慢）
        launchTurnDuration: 0.4,         // 0.4秒 發射轉向持續時間（更長）
        autoReturnTurnSpeed: 7.0         // 2.0 弧度/秒 自動返回轉向速度（更穩定）
    )

    /// 平衡配置 - 中庸之道
    static let balanced = FlyingSwordConfig(
        swordWeight: 0.5,
        swordLength: 0.8,
        velocityThreshold: 0.2,
        velocityMultiplier: 2.0,
        minFlyingSpeed: 0.1,
        maxFlyingTime: 10000.0,          // 10000秒
        dragCoefficient: 0.15,           // 適度阻力
        gravity: -9.8,
        gravityFactor: 0.3,
        followOffset: 0.12,
        maxHistoryCount: 30,
        minSampleInterval: 1.0 / 60.0,
        velocityWindow: 0.25,
        minEffectiveWindow: 0.15,
        minSamplesForLaunch: 5,
        launchCooldown: 0.8,
        remoteControlStrength: 1.0,      // 標準遙控
        fingerInfluenceRatio: 2.0,       // 標準手指影響
        maxRemoteControlDistance: 100.0,
        maxVelocityChange: 5.0,          // 5 m/s 最大變化
        maxFingerHistoryCount: 10,
        minFingerSampleInterval: 1.0 / 30.0,
        collisionDetectionDelay: 1.0,    // 1秒後才開始碰撞檢測
        autoReturnDistance: 0.05,        // 5公分自動返回
        autoReturnDelay: 1.0,            // 1秒後才檢測自動返回
        pinchGestureThreshold: 0.02,     // 2公分捏合識別
        recallSpeed: 1,                // 0.5 m/s 召回初始速度
        maxRecallSpeed: 3.0,             // 3.0 m/s 召回最大速度
        maxRecallSpeedTime: 6.0,         // 6秒達到最大速度（0-3秒保持低速）
        recallTurnSpeed: 3.0,            // 3.0 弧度/秒 轉向速度
        launchTurnSpeed: 5.0,            // 5.0 弧度/秒 發射轉向速度
        launchTurnDuration: 0.3,         // 0.3秒 發射轉向持續時間
        autoReturnTurnSpeed: 7.0         // 3.0 弧度/秒 自動返回轉向速度
    )
}
