import Foundation

/// 傷害數字顯示配置
struct DamageTextConfig {

    /// 文字大小（字體 size）
    var fontSize: Float = 0.5

    /// 向上飄動速度（米/秒）
    var floatSpeed: Float = 1  // 預設 0.5m / 2秒 = 0.25 m/s

    /// 淡出持續時間（秒）
    var fadeDuration: TimeInterval = 1.5

    /// 初始位置偏移（相對於應該顯示的位置，向上偏移多少米）
    var initialOffsetY: Float = 0.0

    /// 文字厚度（擠出深度）
    var extrusionDepth: Float = 0.02

    // MARK: - 速度影響參數

    /// 飛劍速度對飄動速度的影響百分比（0.0 = 不影響，1.0 = 100%影響）
    /// 例如：0.5 表示飛劍速度每增加 1 m/s，飄動速度增加 50%
    var speedInfluenceOnFloatSpeed: Float = 0.8

    /// 飛劍速度對顯示時間的影響百分比（0.0 = 不影響，1.0 = 100%影響）
    /// 例如：0.3 表示飛劍速度每增加 1 m/s，顯示時間減少 30%
    /// 注意：這個值會讓顯示時間變短（速度越快，消失越快）
    var speedInfluenceOnDuration: Float = 0.5

    /// 飛劍速度對顯示間隔的影響百分比（0.0 = 不影響，1.0 = 100%影響）
    /// 例如：0.5 表示飛劍速度每增加 1 m/s，顯示間隔減少 50%
    /// 注意：這個值會讓間隔時間變短（速度越快，傷害數字顯示越密集）
    /// 最小間隔不會低於 0.05 秒（避免太密集）
    var speedInfluenceOnInterval: Float = 0.5

    /// 基礎顯示間隔（秒）- 當飛劍速度為 0 時的間隔
    var baseDisplayInterval: TimeInterval = 0.1

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
