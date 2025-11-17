import RealityKit

/// 碰撞過濾器設置
/// 用於控制哪些物體之間會發生物理碰撞
enum CollisionFilterSetup {

    /// 碰撞組定義（使用 RealityKit 的 CollisionGroup）
    static let swordGroup = CollisionGroup(rawValue: 1 << 0)      // 飛劍
    static let enemyGroup = CollisionGroup(rawValue: 1 << 1)      // 敵人
    static let sceneGroup = CollisionGroup(rawValue: 1 << 2)      // 場景物體

    /// 為飛劍設置碰撞過濾器
    /// 飛劍會與場景碰撞（反彈），並與敵人觸發事件（穿透）
    static func setupSwordCollision() -> CollisionFilter {
        return CollisionFilter(
            group: swordGroup,
            mask: [sceneGroup, enemyGroup]  // 與場景產生物理碰撞，與敵人觸發事件
        )
    }

    /// 為敵人設置碰撞過濾器
    /// 敵人不與任何東西產生物理碰撞（mask 為空）
    /// 但因為飛劍的 mask 包含 enemyGroup，所以碰撞事件仍會觸發
    static func setupEnemyCollision() -> CollisionFilter {
        return CollisionFilter(
            group: enemyGroup,
            mask: CollisionGroup()  // 空 mask：不與任何東西產生物理碰撞
        )
    }

    /// 為場景設置碰撞過濾器
    /// 場景與飛劍產生物理碰撞
    static func setupSceneCollision() -> CollisionFilter {
        return CollisionFilter(
            group: sceneGroup,
            mask: swordGroup  // 只與飛劍產生物理碰撞
        )
    }
}
