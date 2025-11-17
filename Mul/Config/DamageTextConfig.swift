import Foundation

/// 傷害數字顯示配置
struct DamageTextConfig {

    /// 文字大小（字體 size）
    var fontSize: Float = 0.5

    /// 向上飄動速度（米/秒）
    var floatSpeed: Float = 1  // 預設 0.5m / 2秒 = 0.25 m/s

    /// 淡出持續時間（秒）
    var fadeDuration: TimeInterval = 2.0

    /// 初始位置偏移（相對於應該顯示的位置，向上偏移多少米）
    var initialOffsetY: Float = 0.0

    /// 文字厚度（擠出深度）
    var extrusionDepth: Float = 0.02

    // MARK: - 預設配置

    /// 預設配置
    static let `default` = DamageTextConfig()

    /// 快速飄動配置
    static let fast = DamageTextConfig(
        fontSize: 0.4,
        floatSpeed: 0.5,
        fadeDuration: 1.0,
        initialOffsetY: 0.1
    )

    /// 慢速飄動配置
    static let slow = DamageTextConfig(
        fontSize: 0.6,
        floatSpeed: 0.1,
        fadeDuration: 3.0,
        initialOffsetY: 0.2
    )

    /// 楓之谷風格配置
    static let maplestory = DamageTextConfig(
        fontSize: 0.5,
        floatSpeed: 0.3,
        fadeDuration: 1.5,
        initialOffsetY: 0.0
    )
}
