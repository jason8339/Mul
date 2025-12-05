import Foundation
import RealityKit

/// GameSettings 與各系統的集成擴展
/// 提供便捷的配置讀取方法
extension GameSettings {
    /// 獲取當前物理材質配置
    func getPhysicsMaterial() -> PhysicsMaterialResource {
        return .generate(
            staticFriction: Float(staticFriction),
            dynamicFriction: Float(dynamicFriction),
            restitution: Float(restitution)
        )
    }

    /// 獲取當前傷害文字配置
    func getCurrentDamageTextConfig() -> DamageTextConfig {
        return DamageTextConfig(
            fontSize: Float(damageFontSize),
            floatSpeed: Float(damageFloatSpeed),
            fadeDuration: TimeInterval(damageFadeDuration),
            initialOffsetY: Float(damageInitialOffsetY),
            extrusionDepth: 0.02, // 固定值
            speedInfluenceOnFloatSpeed: Float(damageSpeedInfluenceOnFloatSpeed),
            speedInfluenceOnDuration: Float(damageSpeedInfluenceOnDuration),
            speedInfluenceOnInterval: 0.5, // 固定值
            baseDisplayInterval: TimeInterval(0.1) // 固定值
        )
    }

    /// 獲取當前敵人配置
    func getCurrentEnemyConfig() -> EnemyConfig {
        return EnemyConfig(
            scale: Float(enemyScale),
            maxHealth: Float(enemyMaxHealth),
            moveSpeed: Float(enemyMoveSpeed),
            collisionBoxSize: [2.825, 5, 2.102], // 使用預設碰撞箱尺寸
            collisionBoxOffset: [0, 0, 0],
            showCollisionBox: showCollisionBox
        )
    }
}
