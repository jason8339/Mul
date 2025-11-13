import RealityKit
import Foundation

/// A system that handles flying sword physics and behavior.
struct FlyingSwordSystem: System {
    /// The query to find all entities with the flying sword component.
    static let query = EntityQuery(where: .has(FlyingSwordComponent.self))

    /// Debug frame counter for raycast logging
    private static var debugFrameCount = 0

    /// Task for subscribing to collision events (static to persist across struct copies)
    private static var collisionTask: Task<Void, Never>?

    /// Performs updates for all flying swords.
    func update(context: SceneUpdateContext) {
        let swordEntities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for entity in swordEntities {
            guard var swordComponent = entity.components[FlyingSwordComponent.self] else { continue }
            
            if swordComponent.isFlying {
                // Accumulate elapsed flight time using deltaTime
                swordComponent.elapsedTime += context.deltaTime

                // 检查碰撞（使用raycast作为备份，主要依靠物理事件）
                if checkCollision(entity: entity, component: &swordComponent, deltaTime: context.deltaTime, in: context.scene) {
                    // 发生碰撞，停止飞行
                    swordComponent.velocity = .zero
                    swordComponent.resetFlightState()

                    // ⭐ 移除物理引擎组件
                    entity.components.remove(CollisionComponent.self)
                    entity.components.remove(PhysicsBodyComponent.self)
                    entity.components.remove(PhysicsMotionComponent.self)
                    print("💥 飞剑碰撞！停止飞行，禁用物理引擎")

                    entity.components[FlyingSwordComponent.self] = swordComponent
                    continue
                }

                // Update flying sword position and velocity
                updateFlyingSword(entity: entity, component: &swordComponent, deltaTime: context.deltaTime)

                // 檢查是否靠近右手食指指尖（自動返回）
                // 只有在飛行超過指定時間後才開始檢測，避免剛發射就立即返回
                if swordComponent.elapsedTime > swordComponent.config.autoReturnDelay {
                    if let rightIndexTip = HandTrackingSystem.rightIndexTipPosition {
                        let distance = length(entity.position - rightIndexTip)
                        if distance < swordComponent.config.autoReturnDistance {
                            // 如果還沒有開始自動返回轉向，開始轉向
                            if !swordComponent.isAutoReturnTurning {
                                swordComponent.isAutoReturnTurning = true
                                print("✅ 飛劍靠近右手指尖（\(String(format: "%.2f", distance * 100))公分），開始平滑轉向返回")
                            }
                        }
                    }
                }

                // Stop after maximum flying time only (速度過低不會自動結束)
                if swordComponent.elapsedTime > swordComponent.config.maxFlyingTime {
                    // 使用新的重置方法
                    swordComponent.resetFlightState()

                    // ⭐ 移除物理引擎组件
                    entity.components.remove(CollisionComponent.self)
                    entity.components.remove(PhysicsBodyComponent.self)
                    entity.components.remove(PhysicsMotionComponent.self)
                    print("✅ 飛劍飛行結束（超時），禁用物理引擎")
                }

                entity.components[FlyingSwordComponent.self] = swordComponent
            }
        }
    }
    
    /// Updates the position and velocity of a flying sword.
    private func updateFlyingSword(entity: Entity, component: inout FlyingSwordComponent, deltaTime: TimeInterval) {
        // 處理發射初期的平滑轉向
        if component.isLaunchTurning {
            // 檢查是否超過轉向持續時間
            if component.elapsedTime > component.config.launchTurnDuration {
                component.isLaunchTurning = false
                component.launchInitialDirection = nil
            } else if let initialDirection = component.launchInitialDirection {
                // 計算目標方向（速度方向）
                let currentSpeed = length(component.velocity)
                if currentSpeed > 0.01 {
                    let targetDirection = normalize(component.velocity)

                    // 計算兩個方向的夾角
                    let dotProduct = dot(initialDirection, targetDirection)
                    let angle = acos(max(-1.0, min(1.0, dotProduct)))

                    // 計算最大允許的轉向角度
                    let maxTurnAngle = component.config.launchTurnSpeed * Float(deltaTime)

                    // 平滑轉向
                    let newDirection: SIMD3<Float>
                    if angle <= maxTurnAngle || angle < 0.01 {
                        // 已經接近目標方向，結束轉向
                        newDirection = targetDirection
                        component.isLaunchTurning = false
                        component.launchInitialDirection = nil
                    } else {
                        // 使用球面線性插值（SLERP）平滑轉向
                        let t = maxTurnAngle / angle
                        let sinAngle = sin(angle)
                        let a = sin((1.0 - t) * angle) / sinAngle
                        let b = sin(t * angle) / sinAngle
                        newDirection = normalize(a * initialDirection + b * targetDirection)

                        // 更新初始方向為當前方向（下一幀繼續從這個方向開始）
                        component.launchInitialDirection = newDirection
                    }

                    // 更新速度（保持速度大小，只改變方向）
                    component.velocity = newDirection * currentSpeed
                }
            }
        }

        // 處理自動返回的平滑轉向
        if component.isAutoReturnTurning {
            if let rightIndexTip = HandTrackingSystem.rightIndexTipPosition {
                // 計算目標方向（從劍指向手指）
                let toTarget = rightIndexTip - entity.position
                let distance = length(toTarget)

                let targetDirection = normalize(toTarget)

                // 計算當前速度方向
                let currentSpeed = length(component.velocity)
                if currentSpeed > 0.01 {
                    let currentDirection = normalize(component.velocity)

                    // 計算兩個方向的夾角
                    let dotProduct = dot(currentDirection, targetDirection)
                    let angle = acos(max(-1.0, min(1.0, dotProduct)))

                    // 計算最大允許的轉向角度
                    let maxTurnAngle = component.config.autoReturnTurnSpeed * Float(deltaTime)

                    // 檢查距離，如果已經非常接近手指，停止飛行
                    if distance < 0.015 { // 1.5 公分內停止
                        component.resetFlightState()

                        // ⭐ 移除物理引擎组件
                        entity.components.remove(CollisionComponent.self)
                        entity.components.remove(PhysicsBodyComponent.self)
                        entity.components.remove(PhysicsMotionComponent.self)
                        print("✅ 飛劍返回手指，禁用物理引擎")
                        return
                    }

                    // 平滑轉向（持續更新方向以追蹤手指移動）
                    let newDirection: SIMD3<Float>
                    if angle <= maxTurnAngle || angle < 0.01 {
                        // 角度很小，直接對齊目標方向
                        newDirection = targetDirection
                    } else {
                        // 使用球面線性插值（SLERP）平滑轉向
                        let t = maxTurnAngle / angle
                        let sinAngle = sin(angle)
                        let a = sin((1.0 - t) * angle) / sinAngle
                        let b = sin(t * angle) / sinAngle
                        newDirection = normalize(a * currentDirection + b * targetDirection)
                    }

                    // 更新速度（保持速度大小，只改變方向）
                    // 自動返回時速度逐漸減小到返回速度
                    let targetSpeed = component.config.recallSpeed
                    let newSpeed = max(targetSpeed, currentSpeed * 0.95)
                    component.velocity = newDirection * newSpeed
                } else {
                    // 速度太低，重新設置為返回速度
                    component.velocity = targetDirection * component.config.recallSpeed
                }
            } else {
                // 失去手指位置，結束自動返回轉向
                component.isAutoReturnTurning = false
            }
        }

        // 計算手指遙控對速度的影響
        let remoteControlInfluence = component.calculateRemoteControlVelocityChange(swordPosition: entity.position)

        // Apply drag to velocity (考慮劍的重量)
        let drag = 1.0 - (component.config.dragCoefficient * Float(deltaTime))
        component.velocity *= max(0, drag)

        // Apply gravity with factor (可調整重力影響)
        let effectiveGravity = component.config.gravity * component.config.gravityFactor
        component.velocity.y += effectiveGravity * Float(deltaTime)

        // 應用手指遙控影響
        component.velocity += remoteControlInfluence * Float(deltaTime)

        // ⭐ 关键：使用物理引擎更新速度和位置
        if entity.components.has(PhysicsMotionComponent.self) {
            // 有物理组件：更新PhysicsMotionComponent的速度，让物理引擎控制位置
            entity.components[PhysicsMotionComponent.self]?.linearVelocity = component.velocity
        } else {
            // 没有物理组件：手动更新位置（向后兼容）
            let displacement = component.velocity * Float(deltaTime)
            entity.position += displacement
        }

        // Optional: Rotate the sword to point in the direction of movement
        if length(component.velocity) > component.config.minFlyingSpeed {
            let forward = normalize(component.velocity)
            let up = SIMD3<Float>(0, 1, 0)
            let right = normalize(cross(up, forward))
            let newUp = cross(forward, right)

            // Create rotation matrix
            let rotationMatrix = float3x3(right, newUp, forward)
            entity.orientation = simd_quatf(rotationMatrix)
        }
    }

    /// 检查entity是否是剑或剑的子节点
    private static func isSwordEntity(_ checkEntity: Entity, sword: Entity) -> Bool {
        var current: Entity? = checkEntity
        while let entity = current {
            if entity.id == sword.id {
                return true
            }
            current = entity.parent
        }
        return false
    }

    /// 检查飞剑是否与场景发生碰撞（改进版：使用剑尖位置和动态射线长度）
    private func checkCollision(entity: Entity, component: inout FlyingSwordComponent, deltaTime: TimeInterval, in scene: RealityKit.Scene) -> Bool {
        // ⭐ 关键：检查是否超过碰撞检测延迟时间
        guard component.elapsedTime > component.config.collisionDetectionDelay else {
            // 还在延迟期内，不进行碰撞检测
            return false
        }

        // 检查速度
        guard length(component.velocity) > 0.0001 else {
            return false
        }

        // 世界坐标下的剑质心位置
        let worldPos = entity.position(relativeTo: nil)

        // 计算剑的前向方向（使用速度方向）
        let forward = normalize(component.velocity)

        // 计算剑尖的当前位置
        let tipNow = worldPos + forward * component.swordTipOffset

        // 获取上一帧的剑尖位置，如果没有就初始化为当前位置
        let tipPrev = component.lastTipWorld ?? tipNow

        // 本帧预期的剑尖位置（当前位置 + 速度*时间）
        let tipNextExpected = tipNow + component.velocity * Float(deltaTime)

        // 计算射线方向和长度
        let displacement = tipNextExpected - tipPrev
        let distance = length(displacement)

        // 如果位移太小，跳过检测
        guard distance > 0.001 else {
            component.lastTipWorld = tipNow
            return false
        }

        let direction = normalize(displacement)
        // 射线长度 = 位移距离 + 10cm buffer
        let rayLength = distance + 0.1

        // 执行射线检测（先不使用mask，确保能检测到所有物体）
        let results = scene.raycast(
            origin: tipPrev,
            direction: direction,
            length: rayLength,
            query: .nearest,
            relativeTo: nil
        )

        // 调试：每30帧打印一次raycast信息
        Self.debugFrameCount += 1
        if Self.debugFrameCount % 30 == 0 {
            print("🔍 Raycast调试 (第\(Self.debugFrameCount)帧):")
            print("   起点: \(tipPrev)")
            print("   方向: \(direction)")
            print("   长度: \(String(format: "%.2f", rayLength * 100))cm")
            print("   结果数: \(results.count)")
            if results.isEmpty {
                print("   ⚠️ 没有检测到任何物体！")
            } else {
                for (i, result) in results.prefix(3).enumerated() {
                    let hasCollision = result.entity.components.has(CollisionComponent.self)
                    print("   结果[\(i)]: \(result.entity.name) @ \(String(format: "%.2f", result.distance * 100))cm, hasCollision=\(hasCollision)")
                }
            }
        }

        // 更新lastTipWorld（即使碰撞也更新）
        component.lastTipWorld = tipNow

        // 检查是否击中非剑实体
        if let hit = results.first {
            if !Self.isSwordEntity(hit.entity, sword: entity) {
                print("💥 检测到碰撞: \(hit.entity.name) 距离: \(String(format: "%.2f", hit.distance * 100))cm")
                print("   射线: 从 \(tipPrev) 到 \(tipNextExpected), 长度: \(String(format: "%.2f", rayLength * 100))cm")
                print("   碰撞实体位置: \(hit.entity.position(relativeTo: nil))")
                print("   有碰撞组件: \(hit.entity.components.has(CollisionComponent.self))")
                return true
            }
        }

        return false
    }

    init(scene: RealityKit.Scene) {
        // 只订阅一次（检查是否已经订阅）
        if Self.collisionTask == nil {
            Self.collisionTask = Task {
                for await event in scene.subscribe(to: CollisionEvents.Began.self) {
                    Self.handleCollision(event)
                }
            }
            print("✅ FlyingSwordSystem: 已订阅物理碰撞事件")
        }
    }

    /// 处理碰撞事件（静态方法）
    private static func handleCollision(_ event: CollisionEvents.Began) {
        let entityA = event.entityA
        let entityB = event.entityB

        // 检查是否涉及飞剑
        let swordEntity: Entity?
        let otherEntity: Entity?

        if entityA.components.has(FlyingSwordComponent.self) {
            swordEntity = entityA
            otherEntity = entityB
        } else if entityB.components.has(FlyingSwordComponent.self) {
            swordEntity = entityB
            otherEntity = entityA
        } else {
            return // 不涉及飞剑，忽略
        }

        guard let sword = swordEntity,
              var swordComponent = sword.components[FlyingSwordComponent.self] else {
            return
        }

        // 检查飞剑是否正在飞行
        guard swordComponent.isFlying else {
            return // 不在飞行状态，忽略
        }

        // ⭐ 检查碰撞延迟（与raycast一致）
        guard swordComponent.elapsedTime > swordComponent.config.collisionDetectionDelay else {
            return // 还在延迟期内，不处理碰撞
        }

        // 检查是否撞到了剑自己或剑的子节点
        if let other = otherEntity, Self.isSwordEntity(other, sword: sword) {
            return // 撞到自己，忽略
        }

        // ✅ 发生有效碰撞！停止飞行
        print("💥 物理引擎检测到碰撞!")
        if let other = otherEntity {
            print("   碰撞对象: \(other.name)")
            print("   碰撞位置: \(event.position)")
        }

        // 停止飞行
        swordComponent.velocity = .zero
        swordComponent.resetFlightState()

        // 移除物理组件
        sword.components.remove(CollisionComponent.self)
        sword.components.remove(PhysicsBodyComponent.self)
        sword.components.remove(PhysicsMotionComponent.self)

        // 更新组件
        sword.components[FlyingSwordComponent.self] = swordComponent

        print("✅ 飞剑已停止，物理引擎已禁用")
    }
}
