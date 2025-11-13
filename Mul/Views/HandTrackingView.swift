import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

/// A reality view that contains all hand-tracking entities.
struct HandTrackingView: View {
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
            // 从 RealityKitContent bundle 加载场景（使用异步初始化）
            let scene = try await Entity(named: "Oldfactory", in: realityKitContentBundle)

            // 可选：调整场景位置和缩放
            scene.position = [0, 0, 0]  // 场景中心位置
            // scene.scale = [1, 1, 1]   // 如果需要缩放

            // 为场景中的所有物体添加碰撞组件（优化版）
            addCollisionToScene(scene)

            content.add(scene)
            print("✅ 场景 'Oldfactory' 加载成功")
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
                // ⚠️ 关键修复：跳过手部关节实体和剑实体
                let isHandJoint = (child.parent?.components[HandTrackingComponent.self] != nil)
                let isSword = (child.name.contains("Sword") || child.name == "Sword_No1")

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
                        // 添加碰撞组件
                        let collision = CollisionComponent(
                            shapes: [.generateBox(size: size)],
                            mode: .default
                        )
                        modelEntity.components.set(collision)

                        // ⭐ 关键：添加静态物理刚体（物理引擎）
                        let physicsBody = PhysicsBodyComponent(
                            massProperties: .init(mass: 0),  // 质量0 = 无限质量（静态）
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
