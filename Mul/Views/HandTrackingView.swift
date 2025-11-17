import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

/// A reality view that contains all hand-tracking entities.
struct HandTrackingView: View {
    // 從 AppStorage 讀取選擇的地圖
    @AppStorage("selectedMap") private var selectedMapName: String = "Oldfactory"

    /// The main body of the view.
    var body: some View {
        RealityView { content in
            // 先加载场景
            await loadScene(in: content)

            // 再加载手部追踪
            makeHandEntities(in: content)
        }
    }

    /// 加载虚拟场景
    @MainActor
    func loadScene(in content: any RealityViewContentProtocol) async {
        do {
            // 从 RealityKitContent bundle 加载场景（使用选择的地图）
            let scene = try await Entity(named: selectedMapName, in: realityKitContentBundle)

            // 可选：调整场景位置和缩放
            scene.position = [0, 0, 0]  // 场景中心位置
            // scene.scale = [1, 1, 1]   // 如果需要缩放

            // 为场景中的所有物体添加碰撞组件（优化版）
            addCollisionToScene(scene)

            // 調整場景物體的材質（減少不需要的反射）
            adjustSceneMaterials(scene)

            // 添加一個大的不可見地板，確保飛劍不會穿過
            addInvisibleFloor(to: content)

            content.add(scene)
            print("✅ 场景 '\(selectedMapName)' 加载成功")
        } catch {
            print("❌ 加载场景失败: \(error)")
        }
    }

    /// 为场景中的所有物体添加碰撞组件（优化版）
    @MainActor
    func addCollisionToScene(_ entity: Entity) {
        print("🔍 开始为场景添加碰撞组件...")
        print("🔍 场景根实体: \(entity.name)")
        var collisionCount = 0
        var totalEntities = 0
        var modelEntityCount = 0
        var skippedCount = 0

        // 递归遍历所有子实体
        func addCollisionRecursive(_ entity: Entity, depth: Int = 0) {
            totalEntities += 1
            let indent = String(repeating: "  ", count: depth)

            // 打印所有实体（前20个）
            if totalEntities <= 20 {
                print("\(indent)📂 \(entity.name) (类型: \(type(of: entity)))")
            }

            for child in entity.children {
                // ⚠️ 关键修复：跳过手部关节实体、剑实体和敌人实体
                let isHandJoint = (child.parent?.components[HandTrackingComponent.self] != nil)
                let isSword = (child.name.contains("Sword") || child.name == "Sword_No1")
                let isEnemy = (child.name.contains("Enemy") || child.components.has(EnemyComponent.self))

                if isHandJoint {
                    skippedCount += 1
                    if totalEntities <= 20 {
                        print("\(indent)🚫 跳过手部关节: \(child.name)")
                    }
                    continue
                }

                if isSword {
                    skippedCount += 1
                    if totalEntities <= 20 {
                        print("\(indent)🚫 跳过剑实体: \(child.name)")
                    }
                    continue
                }

                if isEnemy {
                    skippedCount += 1
                    if totalEntities <= 20 {
                        print("\(indent)🚫 跳过敌人实体: \(child.name)")
                    }
                    continue
                }

                // 如果是 ModelEntity，尝试添加碰撞
                if let modelEntity = child as? ModelEntity,
                   let model = modelEntity.model {
                    modelEntityCount += 1

                    let bounds = model.mesh.bounds
                    let size = bounds.max - bounds.min

                    // 调试：打印所有ModelEntity
                    if modelEntityCount <= 20 {
                        print("\(indent)📦 ModelEntity: \(modelEntity.name)")
                        print("\(indent)   尺寸: \(size)")
                        print("\(indent)   位置: \(modelEntity.position(relativeTo: nil))")
                    }

                    // 只为有合理尺寸的物体添加碰撞
                    if size.x > 0.01 && size.y > 0.01 && size.z > 0.01 {
                        // 添加碰撞组件（使用場景碰撞過濾器）
                        let collision = CollisionComponent(
                            shapes: [.generateBox(size: size)],
                            mode: .default,
                            filter: CollisionFilterSetup.setupSceneCollision()
                        )
                        modelEntity.components.set(collision)

                        // ⭐ 关键：添加静态物理刚体（物理引擎）
                        let physicsBody = PhysicsBodyComponent(
                            massProperties: .init(mass: 0),  // 质量0 = 无限质量（静态）
                            material: .generate(
                                staticFriction: 0.3,
                                dynamicFriction: 0.2,
                                restitution: 0.7  // 與飛劍相同的彈性係數
                            ),
                            mode: .static
                        )
                        modelEntity.components.set(physicsBody)

                        collisionCount += 1
                        print("\(indent)✅ 碰撞#\(collisionCount): \(modelEntity.name) 尺寸: \(size) [物理引擎]")
                    } else {
                        skippedCount += 1
                        if modelEntityCount <= 20 {
                            print("\(indent)⚠️ 跳过（尺寸太小）: \(modelEntity.name)")
                        }
                    }
                }

                // 递归处理子对象
                addCollisionRecursive(child, depth: depth + 1)
            }
        }

        addCollisionRecursive(entity)
        print(String(repeating: "=", count: 60))
        print("✅ 场景碰撞添加完成统计:")
        print("   总实体数: \(totalEntities)")
        print("   ModelEntity数: \(modelEntityCount)")
        print("   跳过的实体: \(skippedCount)")
        print("   添加碰撞体数: \(collisionCount)")
        print(String(repeating: "=", count: 60))

        if collisionCount == 0 {
            print("⚠️⚠️⚠️ 警告：没有添加任何碰撞体！")
            print("   可能原因：")
            print("   1. 场景中没有ModelEntity")
            print("   2. 所有ModelEntity尺寸太小")
            print("   3. 场景加载失败")
        }
    }

    /// 調整場景物體的材質，減少不需要的反射
    @MainActor
    func adjustSceneMaterials(_ entity: Entity) {
        // ==========================================
        // 🎨 地板反光度設定 - 在這裡調整數值
        // ==========================================
        let floorMetallic: Float = 0.0     // 金屬度 (0.0 = 非金屬, 1.0 = 金屬)
        let floorRoughness: Float = 0.7    // 粗糙度 (0.0 = 光滑/反光, 1.0 = 粗糙/不反光)
        // 建議值：
        // - 光滑木頭地板: roughness = 0.3-0.5
        // - 一般木頭地板: roughness = 0.6-0.8
        // - 粗糙木頭地板: roughness = 0.9-1.0
        // ==========================================

        print("🎨 開始調整場景材質...")
        print("   地板設定: metallic=\(floorMetallic), roughness=\(floorRoughness)")

        func adjustMaterialsRecursive(_ entity: Entity) {
            if let modelEntity = entity as? ModelEntity {
                // 檢查是否是地板（根據名稱或位置判斷）
                let isFloor = modelEntity.name.lowercased().contains("floor") ||
                              modelEntity.name.lowercased().contains("ground") ||
                              modelEntity.position.y < 0.2  // Y < 0.2m 認為是地板

                if isFloor && modelEntity.model != nil {
                    print("   🔧 調整地板材質: \(modelEntity.name)")

                    // 取得原始材質
                    let originalMaterials = modelEntity.model?.materials ?? []

                    // 只修改 PBR 材質的光照屬性，保持原始顏色和紋理
                    let modifiedMaterials = originalMaterials.map { originalMaterial -> RealityKit.Material in
                        if var pbrMaterial = originalMaterial as? PhysicallyBasedMaterial {
                            // 已經是 PBR 材質，只修改光照屬性
                            pbrMaterial.metallic = .init(floatLiteral: floorMetallic)
                            pbrMaterial.roughness = .init(floatLiteral: floorRoughness)
                            pbrMaterial.clearcoat = .init(floatLiteral: 0.0)     // 無清漆層
                            pbrMaterial.clearcoatRoughness = .init(floatLiteral: 1.0)
                            print("      ✓ 已調整 PBR 材質 (roughness=\(floorRoughness))")
                            return pbrMaterial
                        } else if var simpleMaterial = originalMaterial as? SimpleMaterial {
                            // SimpleMaterial - 直接修改其屬性，不轉換為 PBR
                            // 保留所有紋理和顏色
                            simpleMaterial.metallic = .init(floatLiteral: floorMetallic)
                            simpleMaterial.roughness = .init(floatLiteral: floorRoughness)
                            print("      ✓ 已調整 SimpleMaterial (roughness=\(floorRoughness))")
                            return simpleMaterial
                        } else {
                            // 其他材質類型，保持不變
                            print("      ⚠️ 未知材質類型: \(type(of: originalMaterial))，保持原樣")
                            return originalMaterial
                        }
                    }

                    // 替換材質
                    if var model = modelEntity.model {
                        model.materials = modifiedMaterials
                        modelEntity.model = model
                    }
                }
            }

            // 遞歸處理子實體
            for child in entity.children {
                adjustMaterialsRecursive(child)
            }
        }

        adjustMaterialsRecursive(entity)
        print("✅ 材質調整完成")
    }

    /// 添加一個不可見的大地板，確保飛劍不會穿過
    @MainActor
    func addInvisibleFloor(to content: any RealityViewContentProtocol) {
        // 創建一個大的薄地板（100m x 0.1m x 100m）

        // 使用 OcclusionMaterial - 完全不可見，只用於碰撞
        let material = OcclusionMaterial()

        let floorEntity = ModelEntity(
            mesh: .generateBox(size: [100, 0.1, 100]),
            materials: [material]
        )

        // 位置：在地面下方（Y = -0.1），不會遮擋原本的木頭地板
        floorEntity.position = [0, -0.1, 0]
        floorEntity.name = "InvisibleFloor"

        // 添加碰撞組件（使用場景碰撞過濾器）
        let collision = CollisionComponent(
            shapes: [.generateBox(size: [100, 0.1, 100])],
            mode: .default,
            filter: CollisionFilterSetup.setupSceneCollision()
        )
        floorEntity.components.set(collision)

        // 添加靜態物理剛體
        let physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: 0),  // 靜態
            material: .generate(
                staticFriction: 0.3,
                dynamicFriction: 0.2,
                restitution: 0.7  // 與飛劍相同的彈性
            ),
            mode: .static
        )
        floorEntity.components.set(physicsBody)

        content.add(floorEntity)
        print("✅ 已添加不可見地板 (100m x 0.1m x 100m) at Y=0")
    }

    /// Creates the entity that contains all hand-tracking entities.
    @MainActor
    func makeHandEntities(in content: any RealityViewContentProtocol) {
        // Add the left hand.
        let leftHand = Entity()
        leftHand.components.set(HandTrackingComponent(chirality: .left))
        content.add(leftHand)

        // Add the right hand.
        let rightHand = Entity()
        rightHand.components.set(HandTrackingComponent(chirality: .right))
        content.add(rightHand)
    }
}
