import RealityKit
import RealityKitContent
import Foundation

/// 敵人管理系統
struct EnemySystem: System {

    /// 查詢所有帶有 EnemyComponent 的實體
    static let query = EntityQuery(where: .has(EnemyComponent.self))

    // MARK: - 生成配置

    /// 生成間隔（秒）
    private static let spawnInterval: TimeInterval = 10.0

    /// 生成區域範圍（正方形，單位：米）
    private static let spawnAreaSize: Float = 30.0

    /// 玩家附近的排除範圍（單位：米）
    private static let playerExclusionRadius: Float = 10.0

    /// 上次生成時間
    private static var lastSpawnTime: TimeInterval = 0

    /// Task for subscribing to collision events
    private static var collisionTask: Task<Void, Never>?

    /// 已載入的敵人模型（緩存）
    private static var enemyModelCache: Entity?

    /// 場景根實體的弱引用
    private static weak var sceneRoot: Entity?

    /// 場景引用
    private static weak var scene: RealityKit.Scene?

    // MARK: - 初始化

    init(scene: RealityKit.Scene) {
        // 儲存場景引用
        Self.scene = scene

        // 訂閱碰撞事件（飛劍與敵人）
        if Self.collisionTask == nil {
            Self.collisionTask = Task {
                let subscription = scene.subscribe(to: CollisionEvents.Began.self, on: scene) { event in
                    Self.handleCollision(event)
                }
                print("✅ EnemySystem: 已訂閱碰撞事件，訂閱對象: \(subscription)")
            }
            print("✅ EnemySystem: 開始訂閱碰撞事件")
        } else {
            print("ℹ️ EnemySystem: 碰撞事件已經訂閱過了")
        }
    }

    // MARK: - 系統更新

    func update(context: SceneUpdateContext) {
        let currentTime = ProcessInfo.processInfo.systemUptime

        // 從手部追蹤實體獲取場景根實體
        if Self.sceneRoot == nil {
            let handQuery = EntityQuery(where: .has(HandTrackingComponent.self))
            let handEntities = context.entities(matching: handQuery, updatingSystemWhen: .rendering)

            var foundRoot = false
            for hand in handEntities {
                // 找到根實體
                var root = hand
                while let parent = root.parent {
                    root = parent
                }
                Self.sceneRoot = root
                print("✅ 從手部追蹤找到場景根實體: \(root.name)")
                foundRoot = true
                break
            }

            if !foundRoot {
                // 如果找不到手部追蹤實體，嘗試找飛劍
                let swordQuery = EntityQuery(where: .has(FlyingSwordComponent.self))
                let swordEntities = context.entities(matching: swordQuery, updatingSystemWhen: .rendering)

                for sword in swordEntities {
                    var root = sword
                    while let parent = root.parent {
                        root = parent
                    }
                    Self.sceneRoot = root
                    print("✅ 從飛劍找到場景根實體: \(root.name)")
                    break
                }
            }
        }

        // 檢查是否需要生成敵人
        if currentTime - Self.lastSpawnTime >= Self.spawnInterval {
            Self.lastSpawnTime = currentTime
            Task { @MainActor in
                await Self.spawnEnemy()
            }
        }

        // 獲取所有飛劍
        let swordQuery = EntityQuery(where: .has(FlyingSwordComponent.self))
        let swords = context.entities(matching: swordQuery, updatingSystemWhen: .rendering)

        // 更新所有敵人的行為
        let enemies = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for enemy in enemies {
            guard var enemyComponent = enemy.components[EnemyComponent.self] else { continue }

            // 檢查敵人是否存活
            if !enemyComponent.isAlive {
                // 移除死亡的敵人
                enemy.removeFromParent()
                print("🗑️ 移除死亡的敵人")
                continue
            }

            // ⭐ 手動檢測與飛劍的碰撞（距離檢測）
            for sword in swords {
                guard let swordComponent = sword.components[FlyingSwordComponent.self] else { continue }

                // 只檢測飛行中的飛劍
                guard swordComponent.isFlying else { continue }

                // 檢查碰撞延遲
                guard swordComponent.elapsedTime > swordComponent.config.collisionDetectionDelay else { continue }

                // 計算距離
                let enemyPos = enemy.position(relativeTo: nil)
                let swordPos = sword.position(relativeTo: nil)
                let distance = length(enemyPos - swordPos)

                // 碰撞箱半徑：敵人 0.75m（實際碰撞箱寬度的一半） + 飛劍 0.4m（劍長的一半）
                let collisionRadius: Float = 0.75 + 0.4

                if distance < collisionRadius {
                    // 碰撞發生！計算傷害
                    let mass = swordComponent.config.swordWeight
                    let velocity = length(swordComponent.velocity)
                    let kineticEnergy = 0.5 * mass * velocity * velocity
                    let damage = kineticEnergy * 10.0

                    print("⚔️ 手動檢測：飛劍擊中敵人！")
                    print("   距離: \(String(format: "%.2f", distance)) m")
                    print("   質量: \(String(format: "%.2f", mass)) kg")
                    print("   速度: \(String(format: "%.2f", velocity)) m/s")
                    print("   動能: \(String(format: "%.2f", kineticEnergy)) J")
                    print("   傷害: \(String(format: "%.1f", damage))")

                    // 敵人受到傷害
                    let isDead = enemyComponent.takeDamage(damage)

                    // 顯示傷害數字
                    Task { @MainActor in
                        DamageTextSystem.showDamageText(damage: damage, on: enemy)
                    }

                    // 如果敵人死亡，從場景中移除
                    if isDead {
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.5))
                            enemy.removeFromParent()
                        }
                    }

                    // 只處理一次碰撞，避免重複計算傷害
                    break
                }
            }

            // 更新目標位置（玩家位置）
            if let playerPosition = HandTrackingSystem.rightIndexTipPosition {
                enemyComponent.targetPosition = playerPosition
            }

            // 計算移動
            if let direction = enemyComponent.calculateDirectionToTarget(from: enemy.position) {
                // 計算速度（只在水平方向移動，Y軸保持固定）
                var horizontalDirection = direction
                horizontalDirection.y = 0  // 不在 Y 方向移動

                if length(horizontalDirection) > 0.01 {
                    horizontalDirection = normalize(horizontalDirection)
                    enemyComponent.velocity = horizontalDirection * enemyComponent.moveSpeed

                    // kinematic 模式：手動更新位置
                    let displacement = enemyComponent.velocity * Float(context.deltaTime)
                    var newPosition = enemy.position + displacement

                    // ⭐ 鎖定 Y 軸高度，防止穿透地板或飄起
                    // 地板頂部在 Y=-0.05
                    // 敵人高度 1.25m (0.25m * 5)，碰撞箱高度也是 1.25m (0.25m * 5)
                    // 碰撞箱底部應該在地板上：中心 Y = -0.05 + (1.25/2) = 0.575
                    newPosition.y = 0.575

                    enemy.position = newPosition

                    // 讓敵人面向移動方向
                    let forward = normalize(enemyComponent.velocity)
                    let up = SIMD3<Float>(0, 1, 0)
                    let right = normalize(cross(up, forward))
                    let newUp = cross(forward, right)

                    let rotationMatrix = float3x3(right, newUp, forward)
                    enemy.orientation = simd_quatf(rotationMatrix)
                }
            }

            // 更新組件
            enemy.components[EnemyComponent.self] = enemyComponent
        }
    }

    // MARK: - 敵人生成

    /// 在場景中生成敵人
    @MainActor
    private static func spawnEnemy() async {
        // 確保有場景根實體
        guard let root = Self.sceneRoot else {
            print("⚠️ sceneRoot 未初始化，等待下次生成")
            return
        }
        // 獲取玩家位置
        guard let playerPosition = HandTrackingSystem.rightIndexTipPosition else {
            print("⚠️ 無法獲取玩家位置，跳過生成敵人")
            return
        }

        // 調試：打印玩家位置
        print("🎮 玩家位置: X=\(String(format: "%.2f", playerPosition.x)), Y=\(String(format: "%.2f", playerPosition.y)), Z=\(String(format: "%.2f", playerPosition.z))")

        // 計算隨機生成位置
        guard let spawnPosition = generateRandomSpawnPosition(playerPosition: playerPosition) else {
            print("⚠️ 無法找到合適的生成位置")
            return
        }

        // 載入或使用緩存的敵人模型
        let enemyEntity: Entity
        if let cached = Self.enemyModelCache {
            // 複製緩存的模型
            enemyEntity = cached.clone(recursive: true)
        } else {
            // 首次載入
            do {
                let loadedEntity = try await Entity(named: "Enemy-1", in: RealityKitContent.realityKitContentBundle)
                loadedEntity.name = "Enemy-1"
                Self.enemyModelCache = loadedEntity
                enemyEntity = loadedEntity.clone(recursive: true)
                print("✅ 成功載入敵人模型 Enemy-1")
            } catch {
                print("❌ 無法載入敵人模型 Enemy-1: \(error)")
                return
            }
        }

        // 設置位置
        enemyEntity.position = spawnPosition

        // 設置大小（放大五倍）
        enemyEntity.scale = SIMD3<Float>(repeating: 5.0)

        // 調試：打印敵人的邊界框
        let bounds = enemyEntity.visualBounds(relativeTo: nil)
        print("📦 敵人邊界框: min=\(bounds.min), max=\(bounds.max)")
        print("📦 敵人尺寸: \(bounds.max - bounds.min)")

        // 添加 EnemyComponent
        enemyEntity.components.set(EnemyComponent())

        // 添加碰撞組件 - 使用 default 模式配合過濾器：只與飛劍觸發事件
        // 注意：碰撞箱會隨 entity.scale 自動縮放，所以這裡用原始小尺寸
        let enemyFilter = CollisionFilterSetup.setupEnemyCollision()
        let collisionBoxSize: SIMD3<Float> = [0.15, 0.25, 0.15]
        let collision = CollisionComponent(
            shapes: [.generateBox(size: collisionBoxSize)],
            mode: .default,  // default 模式確保碰撞事件觸發
            filter: enemyFilter  // 過濾器：只與飛劍產生事件
        )
        enemyEntity.components.set(collision)
        print("📦 敵人碰撞箱原始大小: \(collisionBoxSize)，實際大小（scale=5.0）: \(collisionBoxSize * 5.0)")

        // ⭐ 添加 kinematic 物理組件：可以觸發碰撞事件，但不受物理影響
        let physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: 100.0),  // 質量不重要，因為是 kinematic
            material: nil,
            mode: .kinematic  // kinematic 模式：不受力影響，但可觸發碰撞事件
        )
        enemyEntity.components.set(physicsBody)
        print("✅ 敵人物理設定: mode=.kinematic（不受力影響，可觸發碰撞事件）")
        print("✅ 敵人碰撞設定: mode=.default, filter.group=\(enemyFilter.group), filter.mask=\(enemyFilter.mask)")

        // 添加到場景根實體
        root.addChild(enemyEntity)

        print("🎯 生成敵人於位置: \(String(format: "(%.2f, %.2f, %.2f)", spawnPosition.x, spawnPosition.y, spawnPosition.z))")
        print("✅ 敵人已成功添加到場景根實體: \(root.name)")
    }

    /// 生成隨機位置（在範圍內但不在玩家附近）
    private static func generateRandomSpawnPosition(playerPosition: SIMD3<Float>) -> SIMD3<Float>? {
        let maxAttempts = 10
        let halfSize = Self.spawnAreaSize / 2.0

        for _ in 0..<maxAttempts {
            // 在 30m x 30m 範圍內隨機生成
            let randomX = Float.random(in: -halfSize...halfSize)
            let randomZ = Float.random(in: -halfSize...halfSize)

            // 地板頂部在 Y=-0.05，敵人高度 1.25m
            // 碰撞箱底部在地板上，中心點在 -0.05 + 0.625 = 0.575
            let randomY: Float = 0.575

            let position = SIMD3<Float>(randomX, randomY, randomZ)

            // 檢查是否在玩家 10m 範圍外
            let distanceToPlayer = length(position - playerPosition)
            if distanceToPlayer >= Self.playerExclusionRadius {
                return position
            }
        }

        // 如果嘗試多次都失敗，返回 nil
        return nil
    }

    // MARK: - 碰撞處理

    /// 處理碰撞事件
    private static func handleCollision(_ event: CollisionEvents.Began) {
        let entityA = event.entityA
        let entityB = event.entityB

        // 調試：打印所有碰撞事件
        print("🔔 碰撞事件: \(entityA.name) ↔ \(entityB.name)")
        print("   A 有 Sword: \(entityA.components.has(FlyingSwordComponent.self)), 有 Enemy: \(entityA.components.has(EnemyComponent.self))")
        print("   B 有 Sword: \(entityB.components.has(FlyingSwordComponent.self)), 有 Enemy: \(entityB.components.has(EnemyComponent.self))")

        // 檢查是否是飛劍與敵人的碰撞
        let swordEntity: Entity?
        let enemyEntity: Entity?

        if entityA.components.has(FlyingSwordComponent.self) && entityB.components.has(EnemyComponent.self) {
            swordEntity = entityA
            enemyEntity = entityB
        } else if entityB.components.has(FlyingSwordComponent.self) && entityA.components.has(EnemyComponent.self) {
            swordEntity = entityB
            enemyEntity = entityA
        } else {
            return  // 不是飛劍與敵人的碰撞，忽略
        }

        guard let sword = swordEntity,
              let enemy = enemyEntity,
              let swordComponent = sword.components[FlyingSwordComponent.self],
              var enemyComponent = enemy.components[EnemyComponent.self] else {
            return
        }

        // 檢查飛劍是否在飛行中
        guard swordComponent.isFlying else {
            return
        }

        // 計算動能傷害：KE = 1/2 * m * v^2
        let mass = swordComponent.config.swordWeight  // kg
        let velocity = length(swordComponent.velocity)  // m/s
        let kineticEnergy = 0.5 * mass * velocity * velocity  // 焦耳

        // 將動能轉換為傷害值（可以調整比例）
        let damage = kineticEnergy * 10.0  // 假設 1 焦耳 = 10 點傷害

        print("⚔️ 飛劍擊中敵人！")
        print("   質量: \(String(format: "%.2f", mass)) kg")
        print("   速度: \(String(format: "%.2f", velocity)) m/s")
        print("   動能: \(String(format: "%.2f", kineticEnergy)) J")
        print("   傷害: \(String(format: "%.1f", damage))")

        // 敵人受到傷害
        let isDead = enemyComponent.takeDamage(damage)

        // 更新組件
        enemy.components[EnemyComponent.self] = enemyComponent

        // 顯示傷害數字
        Task { @MainActor in
            DamageTextSystem.showDamageText(damage: damage, on: enemy)
        }

        // 如果敵人死亡，從場景中移除
        if isDead {
            // 延遲移除，讓死亡動畫有時間播放（如果有的話）
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                enemy.removeFromParent()
            }
        }
    }
}
