# 飛劍碰撞系統升級指南

## 🎯 當前實現 vs 物理引擎方案

### ✅ 當前實現（Raycast方案）- 已修復
**優點**:
- 簡單易用，性能開銷小
- 不影響現有的手勢控制邏輯
- 適合目前的"手動控制飛劍"玩法

**實現細節**:
- 射線起點向前偏移0.45m，避免擊中劍自己
- 使用CollisionGroup過濾，只檢測場景物體
- 檢測距離15cm，足夠覆蓋高速飛行

**適用場景**: ✅ 推薦用於當前項目

---

### 🚀 物理引擎方案（進階）

如果您想要更真實的物理交互，可以考慮升級到完整的物理引擎方案。

## 📋 物理引擎實現步驟

### 1. 為飛劍添加物理組件

```swift
// 在 HandTrackingSystem.swift 的 findSwordInScene 函數中

// 添加物理剛體組件
let physicsBody = PhysicsBodyComponent(
    massProperties: .init(mass: swordComponent.config.swordWeight),  // 使用配置的劍重量
    material: .generate(
        staticFriction: 0.3,
        dynamicFriction: 0.2,
        restitution: 0.1  // 彈性係數
    ),
    mode: .dynamic  // 動態剛體
)
sword.components.set(physicsBody)

// 添加物理運動組件
let physicsMotion = PhysicsMotionComponent(
    linearVelocity: .zero,
    angularVelocity: .zero
)
sword.components.set(physicsMotion)

// 更新碰撞組件為物理模式
let collision = CollisionComponent(
    shapes: [.generateBox(size: [0.05, 0.05, 0.8])],
    mode: .default,  // 使用default而非trigger
    filter: .init(
        group: CollisionGroup(rawValue: 1 << 1),
        mask: CollisionGroup(rawValue: 1 << 0)
    )
)
sword.components.set(collision)
```

### 2. 為場景添加靜態碰撞

```swift
// 在 HandTrackingView.swift 的 addCollisionToScene 函數中

// 為場景物體添加靜態物理組件
if let modelEntity = child as? ModelEntity {
    // 添加靜態物理剛體
    let staticBody = PhysicsBodyComponent(
        massProperties: .init(mass: 0),  // 質量0表示無限質量（靜態）
        mode: .static
    )
    modelEntity.components.set(staticBody)

    // 碰撞組件（已有）
    let collision = CollisionComponent(
        shapes: [.generateBox(size: size)],
        mode: .default,
        filter: .init(
            group: CollisionGroup(rawValue: 1 << 0),
            mask: CollisionGroup(rawValue: 1 << 1)
        )
    )
    modelEntity.components.set(collision)
}
```

### 3. 訂閱碰撞事件

```swift
// 在 HandTrackingView.swift 的 RealityView 中

RealityView { content in
    await loadScene(in: content)
    makeHandEntities(in: content)
} update: { content in
    // 訂閱碰撞事件

} attachments: {
    // 附件
}
.task {
    // 訂閱場景的碰撞事件
    if let scene = content.entities.first?.scene {
        for await event in scene.subscribe(to: CollisionEvents.Began.self) {
            handleCollision(event)
        }
    }
}

// 碰撞處理函數
@MainActor
func handleCollision(_ event: CollisionEvents.Began) {
    // 檢查是否是飛劍的碰撞
    let entityA = event.entityA
    let entityB = event.entityB

    // 判斷哪個是飛劍
    if entityA.name == "Sword_No1" || entityB.name == "Sword_No1" {
        let sword = entityA.name == "Sword_No1" ? entityA : entityB
        let obstacle = entityA.name == "Sword_No1" ? entityB : entityA

        print("💥 飛劍碰撞: \(obstacle.name)")

        // 停止飛劍
        if var swordComponent = sword.components[FlyingSwordComponent.self] {
            swordComponent.resetFlightState()
            sword.components[FlyingSwordComponent.self] = swordComponent
        }

        // 可選：播放音效、粒子效果等
        playCollisionEffect(at: sword.position(relativeTo: nil))
    }
}
```

### 4. 改進手勢控制（使用力/速度而非直接設置位置）

```swift
// 在 FlyingSwordSystem.swift 的 updateFlyingSword 函數中

// 不要直接設置 entity.position
// 改為設置物理速度

if var physicsMotion = entity.components[PhysicsMotionComponent.self] {
    // 設置線速度
    physicsMotion.linearVelocity = component.velocity

    // 可選：添加遙控力
    let remoteControlForce = component.calculateRemoteControlVelocityChange(
        swordPosition: entity.position
    )

    // 施加力（而非直接改變速度）
    if let physicsBody = entity.components[PhysicsBodyComponent.self] {
        let impulse = remoteControlForce * Float(deltaTime) * physicsBody.massProperties.mass
        physicsMotion.linearVelocity += impulse / physicsBody.massProperties.mass
    }

    entity.components[PhysicsMotionComponent.self] = physicsMotion
}
```

### 5. 防止高速穿牆（CCD替代方案）

```swift
// 在 FlyingSwordSystem.swift 中添加手動CCD

private func preventTunneling(
    entity: Entity,
    component: inout FlyingSwordComponent,
    deltaTime: TimeInterval,
    scene: RealityKit.Scene
) {
    let currentPos = entity.position(relativeTo: nil)
    let velocity = component.velocity
    let nextPos = currentPos + velocity * Float(deltaTime)

    // 從當前位置到下一幀位置做射線檢測
    let direction = normalize(nextPos - currentPos)
    let distance = length(nextPos - currentPos)

    let results = scene.raycast(
        origin: currentPos,
        direction: direction,
        length: distance,
        query: .nearest,
        mask: CollisionGroup(rawValue: 1 << 0),
        relativeTo: nil
    )

    if let hit = results.first, !isSwordEntity(hit.entity, sword: entity) {
        // 發現碰撞，停在碰撞點
        entity.position = hit.position
        component.velocity = .zero
        component.resetFlightState()
        print("💥 高速碰撞檢測: \(hit.entity.name)")
    }
}
```

## 🎮 進階碰撞互動效果

### 插入牆壁效果

```swift
func handleWallInsertion(sword: Entity, collision: CollisionEvents.Began) {
    // 獲取碰撞法線
    let normal = collision.contactNormal

    // 將劍沿法線微退
    sword.position -= normal * 0.01

    // 鎖定劍為kinematic（不再受物理影響）
    if var physicsBody = sword.components[PhysicsBodyComponent.self] {
        physicsBody.mode = .kinematic
        sword.components[PhysicsBodyComponent.self] = physicsBody
    }

    // 設置"插入"狀態
    if var swordComponent = sword.components[FlyingSwordComponent.self] {
        swordComponent.isFlying = false
        swordComponent.velocity = .zero
        // 可添加新狀態: isInserted = true
        sword.components[FlyingSwordComponent.self] = swordComponent
    }

    print("🗡️ 飛劍插入牆壁！")
}
```

### 擦牆火花效果

```swift
func handleWallScrape(sword: Entity, collision: CollisionEvents.Began, velocity: SIMD3<Float>) {
    let normal = collision.contactNormal
    let velocityDir = normalize(velocity)

    // 計算夾角
    let angle = acos(dot(velocityDir, normal))

    // 如果是擦撞（夾角小於30度）
    if abs(angle - .pi/2) < .pi/6 {
        // 產生火花粒子
        spawnSparkParticles(at: collision.position)

        // 播放音效
        playScrapingSound()

        // 速度略降
        if var swordComponent = sword.components[FlyingSwordComponent.self] {
            swordComponent.velocity *= 0.9
            sword.components[FlyingSwordComponent.self] = swordComponent
        }

        print("✨ 擦牆火花！")
    }
}
```

### 反彈效果

```swift
func handleBounce(sword: Entity, collision: CollisionEvents.Began, velocity: SIMD3<Float>) {
    let normal = collision.contactNormal
    let restitution: Float = 0.3  // 彈性係數

    // 反彈公式: v' = v - (1+e)*(v·n)*n
    let velocityAlongNormal = dot(velocity, normal)
    let bounceVelocity = velocity - (1.0 + restitution) * velocityAlongNormal * normal

    // 更新速度
    if var swordComponent = sword.components[FlyingSwordComponent.self] {
        swordComponent.velocity = bounceVelocity * 0.8  // 損失一些能量
        sword.components[FlyingSwordComponent.self] = swordComponent
    }

    print("🎾 飛劍反彈！")
}
```

## ⚖️ 方案對比

| 特性 | Raycast方案（當前） | 物理引擎方案 |
|------|---------------------|--------------|
| 實現難度 | ⭐ 簡單 | ⭐⭐⭐ 中等 |
| 性能開銷 | ⭐⭐⭐⭐⭐ 很低 | ⭐⭐⭐ 中等 |
| 真實感 | ⭐⭐⭐ 足夠 | ⭐⭐⭐⭐⭐ 非常真實 |
| 與手勢控制兼容性 | ⭐⭐⭐⭐⭐ 完美 | ⭐⭐⭐ 需要調整 |
| 碰撞準確性 | ⭐⭐⭐⭐ 高 | ⭐⭐⭐⭐⭐ 非常高 |
| 進階效果支持 | ⭐⭐ 有限 | ⭐⭐⭐⭐⭐ 豐富 |

## 💡 建議

**當前階段**: 繼續使用已修復的Raycast方案
- ✅ 已解決"擊中自己"的問題
- ✅ 性能優秀，適合手勢控制
- ✅ 碰撞檢測可靠

**未來升級**: 如果需要以下功能，考慮物理引擎方案
- 劍插入牆壁並留在原地
- 真實的反彈效果
- 與多個物體的複雜互動
- 破壞效果（擊碎物體）

## 📝 注意事項

1. **物理引擎與手動控制的衝突**:
   - 使用物理引擎時，不能直接設置`entity.position`
   - 需要通過設置速度或施加力來控制

2. **性能考慮**:
   - 場景中大量動態剛體會影響性能
   - 建議場景物體使用靜態剛體

3. **調試技巧**:
   - 開啟物理調試視圖查看碰撞盒
   - 監控碰撞事件頻率

---

**總結**: 當前的Raycast方案已經足夠好。只有在需要更複雜的物理互動時，才考慮升級到物理引擎方案。
