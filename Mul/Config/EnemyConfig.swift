import Foundation
import simd

/// 敵人配置
struct EnemyConfig {

    /// 敵人的縮放比例（相對於原始模型大小）
    var scale: Float = 1.0

    /// 敵人的最大血量
    var maxHealth: Float = 100.0

    /// 敵人的移動速度 (m/s)
    var moveSpeed: Float = 0.1

    /// 碰撞箱原始大小（會隨 scale 自動縮放）
    /// X: 左右寬度, Y: 上下高度, Z: 前後深度
    /// 這個尺寸會隨著 scale 自動縮放，例如 scale=2.0 時，實際碰撞箱是 [0.3, 0.5, 0.3]
    /// 建議值（覆蓋模型100%）：[2.825, 5.0, 2.102]
    var collisionBoxSize: SIMD3<Float> = [2.825, 5, 2.102]

    /// 碰撞箱中心點偏移（用於修正模型中心點不在正中間的情況）
    /// 模型中心已在 Blender 中修正為模型中心，所以不需要偏移
    var collisionBoxOffset: SIMD3<Float> = [0, 0, 0]

    /// 是否顯示碰撞箱（調試用）
    /// true: 顯示白色線框，false: 隱藏
    var showCollisionBox: Bool = false

    // MARK: - 預設配置

    /// 預設配置
    static let `default` = EnemyConfig()

    /// 小型敵人
    static let small = EnemyConfig(
        scale: 3.0,
        maxHealth: 50.0,
        moveSpeed: 0.15,
        collisionBoxSize: [0.15, 0.25, 0.15]
    )

    /// 大型敵人
    static let large = EnemyConfig(
        scale: 8.0,
        maxHealth: 200.0,
        moveSpeed: 0.05,
        collisionBoxSize: [0.15, 0.25, 0.15]
    )

    /// 巨型BOSS
    static let boss = EnemyConfig(
        scale: 15.0,
        maxHealth: 1000.0,
        moveSpeed: 0.03,
        collisionBoxSize: [0.2, 0.3, 0.2]
    )
}
