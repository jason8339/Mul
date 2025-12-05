import RealityKit
import RealityKitContent
import ARKit
import SwiftUI

/// A system that provides hand-tracking capabilities.
struct HandTrackingSystem: System {
    /// The active ARKit session.
    @MainActor static var arSession = ARKitSession()

    /// The provider instance for hand-tracking.
    @MainActor static let handTracking = HandTrackingProvider()

    /// The most recent anchor that the provider detects on the left hand.
    @MainActor static var latestLeftHand: HandAnchor?

    /// The most recent anchor that the provider detects on the right hand.
    @MainActor static var latestRightHand: HandAnchor?

    /// 右手食指指尖的世界座標位置（用於飛劍距離檢測）
    @MainActor static var rightIndexTipPosition: SIMD3<Float>?

    /// 左手食指指尖的世界座標位置（用於手勢檢測）
    @MainActor static var leftIndexTipPosition: SIMD3<Float>?

    /// 左手大拇指指尖的世界座標位置（用於手勢檢測）
    @MainActor static var leftThumbTipPosition: SIMD3<Float>?

    /// Guard to ensure ARKit session starts only once.
    @MainActor private static var didStartSession = false

    init(scene: RealityKit.Scene) {
        // 不要在 System 初始化時啟動 ARKit 或註冊其他 System。
    }

    /// 在場景中尋找劍實體（不再预先添加碰撞组件）
    @MainActor
    private func findSwordInScene(scene: RealityKit.Scene) -> Entity? {
        guard let sword = scene.findEntity(named: "Sword_No1") else {
            return nil
        }
        return sword
    }
    
    /// 更新劍的位置以跟隨手指：
    /// - 旋轉：沿用 tip 的旋轉，然後繞 tip 的本地 +Y 軸旋轉 180 度做校正
    /// - 位置：沿 dir（tip -> intermediateTip）外推 followOffset
    @MainActor
    private func updateSwordPositionToFollowFinger(
        swordEntity: Entity,
        handAnchor: HandAnchor,
        handSkeleton: HandSkeleton,
        anchorFromJointTransform: simd_float4x4,
        followOffset: Float
    ) {
        // 取得 tip 與 intermediateTip 的世界變換
        let anchorFromTip = anchorFromJointTransform
        let tipWorldTransform = handAnchor.originFromAnchorTransform * anchorFromTip
        
        let anchorFromIntermediate = handSkeleton.joint(.indexFingerIntermediateTip).anchorFromJointTransform
        let intermediateWorldTransform = handAnchor.originFromAnchorTransform * anchorFromIntermediate
        
        // 世界座標位置
        let tipWorldPos = SIMD3<Float>(
            tipWorldTransform.columns.3.x,
            tipWorldTransform.columns.3.y,
            tipWorldTransform.columns.3.z
        )
        let intermediateWorldPos = SIMD3<Float>(
            intermediateWorldTransform.columns.3.x,
            intermediateWorldTransform.columns.3.y,
            intermediateWorldTransform.columns.3.z
        )
        
        // 計算「前方」方向 dir：優先 tip - intermediateTip
        var dir = tipWorldPos - intermediateWorldPos
        var dirLen = length(dir)
        if dirLen > 1e-4 {
            dir /= dirLen
        } else {
            // 退化情況，用 tip 的 z 軸作為方向，仍退化則預設 -Z
            let forwardZ = SIMD3<Float>(tipWorldTransform.columns.2.x,
                                        tipWorldTransform.columns.2.y,
                                        tipWorldTransform.columns.2.z)
            let fLen = length(forwardZ)
            dir = fLen > 1e-4 ? forwardZ / fLen : SIMD3<Float>(0, 0, -1)
        }
        // 最終保底
        dirLen = length(dir)
        if dirLen <= 1e-6 {
            dir = SIMD3<Float>(0, 0, -1)
        }
        
        // 外推到指尖前方一段距離（位置保持原邏輯）
        let targetPos = tipWorldPos + dir * followOffset
        
        // 從 tipWorldTransform 取出「tip 的旋轉基底」(3x3)
        let tipRight = SIMD3<Float>(tipWorldTransform.columns.0.x,
                                    tipWorldTransform.columns.0.y,
                                    tipWorldTransform.columns.0.z) // tip 的 +X
        let tipUp    = SIMD3<Float>(tipWorldTransform.columns.1.x,
                                    tipWorldTransform.columns.1.y,
                                    tipWorldTransform.columns.1.z) // tip 的 +Y
        let tipFwd   = SIMD3<Float>(tipWorldTransform.columns.2.x,
                                    tipWorldTransform.columns.2.y,
                                    tipWorldTransform.columns.2.z) // tip 的 +Z
        
        let M = float3x3(columns: (tipRight, tipUp, tipFwd)) // 將 tip 的本地基底放到世界
        
        // 本地繞 +Y 軸 180 度的旋轉（校正前/後顛倒）
        let c: Float = -1.0  // cos(π)
        let s: Float =  0.0  // sin(π)
        let RlocalY180 = float3x3(columns: (
            SIMD3<Float>( c,  0,  s), // [ cosθ, 0, sinθ ]
            SIMD3<Float>( 0,  1,  0), // [ 0,    1, 0    ]
            SIMD3<Float>(-s,  0,  c)  // [-sinθ, 0, cosθ ]
        ))
        
        // 世界座標中的校正旋轉：M * Rlocal * M^T
        let M_T = M.transpose
        let correction = M * RlocalY180 * M_T
        
        // 將 tip 的旋轉乘上校正，得到最終旋轉基底
        let correctedRight = correction * tipRight
        let correctedUp    = correction * tipUp
        let correctedFwd   = correction * tipFwd
        
        // 組合 4x4 變換（使用修正後旋轉 + 目標平移）
        var placed = matrix_identity_float4x4
        placed.columns.0 = SIMD4<Float>(correctedRight.x, correctedRight.y, correctedRight.z, 0)
        placed.columns.1 = SIMD4<Float>(correctedUp.x,    correctedUp.y,    correctedUp.z,    0)
        placed.columns.2 = SIMD4<Float>(correctedFwd.x,   correctedFwd.y,   correctedFwd.z,   0)
        placed.columns.3 = SIMD4<Float>(targetPos.x,      targetPos.y,      targetPos.z,      1)
        
        swordEntity.setTransformMatrix(placed, relativeTo: nil)
    }
    
    @MainActor
    private static func runSession() async {
        do {
            try await arSession.run([handTracking])
        } catch let error as ARKitSession.Error {
            print("The app has encountered an error while running providers: \(error.localizedDescription)")
        } catch {
            print("The app has encountered an unexpected error: \(error.localizedDescription)")
        }

        // Collect each hand-tracking anchor on main actor.
        for await anchorUpdate in handTracking.anchorUpdates {
            switch anchorUpdate.anchor.chirality {
            case .left:
                Self.latestLeftHand = anchorUpdate.anchor
            case .right:
                Self.latestRightHand = anchorUpdate.anchor
            @unknown default:
                break
            }
        }
    }
    
    /// The query this system uses to find all entities with the hand-tracking component.
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    /// Performs any necessary updates to the entities with the hand-tracking component.
    /// - Parameter context: The context for the system to update.
    func update(context: SceneUpdateContext) {
        // 延後啟動 ARKit session 到第一次 update，確保場景已完全就緒。
        if !Self.didStartSession {
            Self.didStartSession = true
            Task { @MainActor in
                await Self.runSession()
            }
        }

        let handEntities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)

        for handEntity in handEntities {
            guard var handComponent = handEntity.components[HandTrackingComponent.self] else { continue }

            // 初始化 joints：只做一次（同步標記，避免多幀重入）
            if !handComponent.hasInitialized {
                handComponent.hasInitialized = true
                handEntity.components.set(handComponent)
                Task { @MainActor in
                    await self.addJoints(to: handEntity, handComponent: &handComponent)
                    // 回寫（確保 fingers 填好）
                    handEntity.components.set(handComponent)
                }
                // 本幀暫不更新
                continue
            }

            // 取得對應手的 anchor
            let handAnchor: HandAnchor? = {
                switch handComponent.chirality {
                case .left: return Self.latestLeftHand
                case .right: return Self.latestRightHand
                default: return nil
                }
            }()
            guard let handAnchor, let handSkeleton = handAnchor.handSkeleton else { continue }

            // 預先取得手腕（forearmWrist）transform，供相對座標計算
            let anchorFromWrist = handSkeleton.joint(.forearmWrist).anchorFromJointTransform
            let wristFromAnchor = anchorFromWrist.inverse

            // 逐關節更新位置
            for (jointName, jointNode) in handComponent.fingers {
                let anchorFromJointTransform = handSkeleton.joint(jointName).anchorFromJointTransform

                // 右手食指 tip：處理飛劍
                if jointName == .indexFingerTip && handComponent.chirality == .right {
                    // 更新右手食指指尖的世界位置（用於距離檢測）
                    let tipWorldTransform = handAnchor.originFromAnchorTransform * anchorFromJointTransform
                    Self.rightIndexTipPosition = SIMD3<Float>(
                        tipWorldTransform.columns.3.x,
                        tipWorldTransform.columns.3.y,
                        tipWorldTransform.columns.3.z
                    )

                    // 尋找場景根目錄中的劍實體
                    if let scene = handEntity.scene,
                       let swordEntity = findSwordInScene(scene: scene) {
                        
                        if var swordComponent = swordEntity.components[FlyingSwordComponent.self] {
                            if !swordComponent.isFlying {
                                // 計算 tip 在手腕座標系的局部位置（以 forearmWrist 為參考）
                                let wristFromTip = wristFromAnchor * anchorFromJointTransform
                                let localPosition = SIMD3<Float>(
                                    wristFromTip.columns.3.x,
                                    wristFromTip.columns.3.y,
                                    wristFromTip.columns.3.z
                                )

                                // 用系統 uptime 當時間戳
                                let timestamp = ProcessInfo.processInfo.systemUptime

                                // 加入取樣（使用相對手腕的局部位置）
                                swordComponent.addPositionSample(position: localPosition, timestamp: timestamp)

                                // 判斷是否發射
                                if swordComponent.shouldLaunch() {
                                    let velocity = swordComponent.calculateLaunchVelocity()
                                    let speed = length(velocity) * 100
                                    print("🚀 發射飛劍！速度: \(speed) cm/s，重量: \(swordComponent.config.swordWeight) kg")

                                    // 記錄發射時劍的當前方向（從劍的 orientation 提取前向向量）
                                    let swordOrientation = swordEntity.orientation
                                    let swordForward = swordOrientation.act(SIMD3<Float>(0, 0, 1))

                                    swordComponent.isFlying = true
                                    swordComponent.velocity = velocity
                                    swordComponent.elapsedTime = 0
                                    swordComponent.launchInitialDirection = normalize(swordForward)
                                    swordComponent.isLaunchTurning = true

                                    // 清空歷史，避免殘留
                                    swordComponent.positionHistory.removeAll(keepingCapacity: true)

                                    // ⭐ 關鍵：發射時添加物理引擎组件
                                    // 1. 碰撞组件（使用碰撞過濾器）
                                    let swordFilter = CollisionFilterSetup.setupSwordCollision()
                                    let collision = CollisionComponent(
                                        shapes: [.generateBox(size: [0.05, 0.05, 0.8])],
                                        mode: .default,  // 使用default模式支持物理
                                        filter: swordFilter  // 與場景碰撞、與敵人觸發事件
                                    )
                                    swordEntity.components.set(collision)
                                    print("⚔️ 飛劍碰撞設定: mode=.default, filter.group=\(swordFilter.group), filter.mask=\(swordFilter.mask)")

                                    // 2. 物理刚体组件（动态）- 使用 GameSettings 配置
                                    let settings = GameSettings.shared
                                    let physicsBody = PhysicsBodyComponent(
                                        massProperties: .init(mass: swordComponent.config.swordWeight),
                                        material: settings.getPhysicsMaterial(),
                                        mode: .dynamic
                                    )
                                    swordEntity.components.set(physicsBody)

                                    // 3. 物理运动组件
                                    let physicsMotion = PhysicsMotionComponent(
                                        linearVelocity: velocity,  // 设置初始速度
                                        angularVelocity: .zero
                                    )
                                    swordEntity.components.set(physicsMotion)

                                    // 確保劍是可見的
                                    swordEntity.isEnabled = true

                                    let launchSpeed = length(velocity) * 100  // 轉換為 cm/s
                                    let launchPos = swordEntity.position(relativeTo: nil)
                                    print("🚀 發射飛劍！")
                                    print("   位置: \(launchPos)")
                                    print("   速度: \(String(format: "%.2f", launchSpeed)) cm/s")
                                    print("   方向: \(normalize(velocity))")
                                    print("✅ 飛行中：啟用物理引擎碰撞檢測")

                                    // 劍已在場景根目錄，直接更新組件
                                    swordEntity.components[FlyingSwordComponent.self] = swordComponent
                                    continue
                                }
                                
                                // 未發射：更新 component
                                swordEntity.components[FlyingSwordComponent.self] = swordComponent
                                
                                // 未發射狀態下，將劍跟隨食指指尖位置（外推一定距離），並沿用 tip 旋轉後再 180° 校正
                                updateSwordPositionToFollowFinger(
                                    swordEntity: swordEntity,
                                    handAnchor: handAnchor,
                                    handSkeleton: handSkeleton,
                                    anchorFromJointTransform: anchorFromJointTransform,
                                    followOffset: swordComponent.config.followOffset
                                )
                            } else {
                                // 🎯 NEW: 飛劍正在飛行中，收集手指位置用於遙控
                                let tipWorldTransform = handAnchor.originFromAnchorTransform * anchorFromJointTransform
                                let fingerWorldPosition = SIMD3<Float>(
                                    tipWorldTransform.columns.3.x,
                                    tipWorldTransform.columns.3.y,
                                    tipWorldTransform.columns.3.z
                                )
                                
                                let timestamp = ProcessInfo.processInfo.systemUptime
                                swordComponent.addFingerPositionSample(position: fingerWorldPosition, timestamp: timestamp)
                                
                                // 更新組件
                                swordEntity.components[FlyingSwordComponent.self] = swordComponent
                            }
                        }
                    }
                }

                // 左手食指 tip：追蹤位置用於手勢檢測
                if jointName == .indexFingerTip && handComponent.chirality == .left {
                    let tipWorldTransform = handAnchor.originFromAnchorTransform * anchorFromJointTransform
                    Self.leftIndexTipPosition = SIMD3<Float>(
                        tipWorldTransform.columns.3.x,
                        tipWorldTransform.columns.3.y,
                        tipWorldTransform.columns.3.z
                    )
                }

                // 左手大拇指 tip：追蹤位置用於手勢檢測
                if jointName == .thumbTip && handComponent.chirality == .left {
                    let tipWorldTransform = handAnchor.originFromAnchorTransform * anchorFromJointTransform
                    Self.leftThumbTipPosition = SIMD3<Float>(
                        tipWorldTransform.columns.3.x,
                        tipWorldTransform.columns.3.y,
                        tipWorldTransform.columns.3.z
                    )
                }

                // 仍然附著在手上的關節才更新位置（jointNode 代表該關節節點）
                jointNode.setTransformMatrix(
                    handAnchor.originFromAnchorTransform * anchorFromJointTransform,
                    relativeTo: nil
                )
            }

            // 檢測左手捏合手勢並觸發飛劍召回
            if handComponent.chirality == .left {
                checkPinchGestureAndRecallSword(in: handEntity.scene)
            }
        }
    }

    /// 檢測左手捏合手勢並觸發飛劍召回
    @MainActor
    /// 根據按壓時長計算召回速度
    /// - Parameters:
    ///   - pressDuration: 按壓持續時間（秒）
    ///   - config: 飛劍配置
    /// - Returns: 計算出的召回速度（m/s）
    /// 階段性捏合控制的召回速度計算
    /// - Stage 1 (0-0.5s): 返回 nil，表示不進行召回
    /// - Stage 2 (0.5-1.5s): 返回固定初始速度 (config.recallSpeed)
    /// - Stage 3 (1.5s+): 線性增加到最大速度 (config.maxRecallSpeed)
    private func calculateRecallSpeed(pressDuration: TimeInterval, config: FlyingSwordConfig) -> Float? {
        // ⭐ Stage 1: 0-0.5秒 - 不召回，讓玩家有時間重新定位右手
        if pressDuration < 0.5 {
            return nil
        }

        // ⭐ Stage 2: 0.5-1.5秒 - 固定初始召回速度
        if pressDuration < 1.5 {
            return config.recallSpeed
        }

        // ⭐ Stage 3: 1.5秒以上 - 速度遞增
        // 使用配置的 maxRecallSpeedTime 來控制加速時間
        // 例如：maxRecallSpeedTime = 6.0 表示從 1.5s 到 6.0s 之間線性加速到最大速度
        let accelerationDuration = config.maxRecallSpeedTime - 1.5
        let timeSinceStage3 = pressDuration - 1.5

        if accelerationDuration > 0 {
            // 線性插值：從 recallSpeed 到 maxRecallSpeed
            let progress = min(1.0, Float(timeSinceStage3 / accelerationDuration))
            let speed = config.recallSpeed + (config.maxRecallSpeed - config.recallSpeed) * progress
            return speed
        } else {
            // 如果 maxRecallSpeedTime <= 1.5，直接返回最大速度
            return config.maxRecallSpeed
        }
    }

    private func checkPinchGestureAndRecallSword(in scene: RealityKit.Scene?) {
        // 確保有左手食指和大拇指的位置
        guard let leftIndexTip = Self.leftIndexTipPosition,
              let leftThumbTip = Self.leftThumbTipPosition,
              let rightIndexTip = Self.rightIndexTipPosition,
              let scene = scene else {
            return
        }

        // 尋找劍實體
        guard let swordEntity = scene.findEntity(named: "Sword_No1"),
              var swordComponent = swordEntity.components[FlyingSwordComponent.self] else {
            return
        }

        // 只在劍飛行中才處理召回
        guard swordComponent.isFlying else {
            // 劍不在飛行時，重置捏合狀態
            if swordComponent.isPinchPressed {
                swordComponent.isPinchPressed = false
                swordComponent.pinchPressStartTime = 0
                swordEntity.components[FlyingSwordComponent.self] = swordComponent
            }
            return
        }

        // 計算左手食指和大拇指的距離
        let pinchDistance = length(leftIndexTip - leftThumbTip)

        // 如果距離小於閾值，視為捏合手勢
        if pinchDistance < swordComponent.config.pinchGestureThreshold {
            // 獲取當前系統時間
            let currentTime = ProcessInfo.processInfo.systemUptime

            // 如果剛開始捏合，記錄開始時間
            if !swordComponent.isPinchPressed {
                swordComponent.isPinchPressed = true
                swordComponent.pinchPressStartTime = currentTime
                print("🤏 開始捏合手勢！")
            }

            // 根據按壓時長計算召回速度
            let pressDuration = currentTime - swordComponent.pinchPressStartTime

            // ⭐ 關鍵修改：如果在 Stage 1 (0-0.5s)，不進行召回
            if let targetSpeed = calculateRecallSpeed(
                pressDuration: pressDuration,
                config: swordComponent.config
            ) {
                // Stage 2 或 Stage 3：進行召回
                // 計算從劍到右手食指指尖的目標方向
                let toTarget = rightIndexTip - swordEntity.position
                let distance = length(toTarget)

                if distance > 0.01 { // 避免除以零
                    let targetDirection = normalize(toTarget)

                    // 獲取當前速度方向和大小
                    let currentSpeed = length(swordComponent.velocity)
                    let currentDirection = currentSpeed > 0.01 ? normalize(swordComponent.velocity) : targetDirection

                    // 計算兩個方向的夾角（用於debug）
                    let dotProduct = dot(currentDirection, targetDirection)
                    let angle = acos(max(-1.0, min(1.0, dotProduct)))

                    // 計算最大允許的轉向角度（假設約60fps，即約0.0167秒一幀）
                    let estimatedDeltaTime: Float = 1.0 / 60.0
                    let maxTurnAngle = swordComponent.config.recallTurnSpeed * estimatedDeltaTime

                    // 如果夾角小於最大轉向角度，直接朝目標方向
                    let newDirection: SIMD3<Float>
                    if angle <= maxTurnAngle || angle < 0.01 {
                        newDirection = targetDirection
                    } else {
                        // 使用球面線性插值（SLERP）平滑轉向
                        let t = maxTurnAngle / angle
                        let sinAngle = sin(angle)
                        let a = sin((1.0 - t) * angle) / sinAngle
                        let b = sin(t * angle) / sinAngle
                        newDirection = normalize(a * currentDirection + b * targetDirection)
                    }

                    swordComponent.velocity = newDirection * targetSpeed

                    // 更新組件
                    swordEntity.components[FlyingSwordComponent.self] = swordComponent

                    // 定期打印召回狀態（每0.5秒打印一次）
                    let printInterval: TimeInterval = 0.5
                    if Int(pressDuration / printInterval) != Int((pressDuration - 0.016) / printInterval) {
                        let stage = pressDuration < 1.5 ? "Stage 2" : "Stage 3"
                        print("🤏 飛劍召回中 [\(stage)] (按壓時長: \(String(format: "%.1f", pressDuration))s, 距離: \(String(format: "%.2f", distance))m, 速度: \(String(format: "%.2f", targetSpeed))m/s)")
                    }
                }
            } else {
                // Stage 1 (0-0.5s)：不召回，保持當前速度
                // 定期提示玩家處於等待階段
                let printInterval: TimeInterval = 0.2
                if Int(pressDuration / printInterval) != Int((pressDuration - 0.016) / printInterval) {
                    print("🤏 [Stage 1] 等待中... (按壓時長: \(String(format: "%.2f", pressDuration))s, 右手可自由移動)")
                }
                // 不修改速度，讓劍繼續當前的飛行狀態
                swordEntity.components[FlyingSwordComponent.self] = swordComponent
            }
        } else {
            // 捏合結束，重置狀態
            if swordComponent.isPinchPressed {
                swordComponent.isPinchPressed = false
                swordComponent.pinchPressStartTime = 0
                swordEntity.components[FlyingSwordComponent.self] = swordComponent
                print("🤏 結束捏合手勢")
            }
        }
    }
    
    /// Performs any necessary setup to the entities with the hand-tracking component.
    /// - Parameters:
    ///   - entity: The entity to perform setup on.
    ///   - handComponent: The hand-tracking component to update.
    @MainActor
    func addJoints(to handEntity: Entity, handComponent: inout HandTrackingComponent) async {
        // For each joint, create a node and attach it to the hand.
        for (jointName, _, _) in Hand.joints {
            // 若已存在 joint 節點就不重複建立
            let jointNode: Entity
            if let existing = handComponent.fingers[jointName] {
                jointNode = existing
            } else {
                jointNode = Entity()
                handEntity.addChild(jointNode)
                handComponent.fingers[jointName] = jointNode
            }

            // 右手食指 tip：放劍（只放一次，但放到場景根目錄）
            let isRightIndexTip = (jointName == .indexFingerTip && handComponent.chirality == .right)
            if isRightIndexTip {
                // 檢查場景根目錄是否已有劍
                let scene = handEntity.scene!
                let alreadyHasSword = scene.findEntity(named: "Sword_No1") != nil
                if !alreadyHasSword {
                    do {
                        let sword = try await Entity(named: "Sword_No1", in: RealityKitContent.realityKitContentBundle)
                        sword.name = "Sword_No1"
                        sword.scale = SIMD3<Float>(repeating: 0.3) // 稍微放大，方便觀察
                        // 把 FlyingSwordComponent 直接掛在劍實體上 - 使用 GameSettings 配置
                        let currentConfig = GameSettings.shared.getCurrentFlyingSwordConfig()
                        sword.components.set(FlyingSwordComponent(config: currentConfig))
                        // 將劍添加到手的根實體的父級（通常是場景的根實體）
                        if let parentEntity = handEntity.parent {
                            parentEntity.addChild(sword)
                        } else {
                            // 如果沒有父實體，添加到手實體的同級
                            handEntity.addChild(sword)
                        }
                        print("✅ 成功載入劍模型並添加到場景根目錄")
                    } catch {
                        print("❌ 無法載入 Sword_No1 模型: \(error)")
                    }
                }
            }
        }
    }
}
