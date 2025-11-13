# 碰撞检测诊断指南

## 🐛 问题：剑穿过地板

你遇到的问题是剑直接穿过场景物体（如地板），没有触发碰撞。

---

## 🔍 诊断步骤

### 步骤1：检查场景碰撞组件是否添加

**运行应用，查看启动日志：**

#### ✅ 正常情况：
```
🔍 开始为场景添加碰撞组件...
🔍 场景根实体: Oldfactory
📂 Oldfactory (类型: Entity)
📦 ModelEntity: Floor
   尺寸: SIMD3<Float>(5.0, 0.1, 5.0)
   位置: SIMD3<Float>(0.0, 0.0, 0.0)
✅ 碰撞#1: Floor 尺寸: SIMD3<Float>(5.0, 0.1, 5.0)
============================================================
✅ 场景碰撞添加完成统计:
   总实体数: 15
   ModelEntity数: 5
   跳过的实体: 8
   添加碰撞体数: 5
============================================================
```

**关键指标**：
- ✅ `添加碰撞体数: > 0`
- ✅ 看到地板/墙壁等场景物体

#### ❌ 问题情况1：没有添加任何碰撞体
```
⚠️⚠️⚠️ 警告：没有添加任何碰撞体！
   可能原因：
   1. 场景中没有ModelEntity
   2. 所有ModelEntity尺寸太小
   3. 场景加载失败
```

**解决方案**：
- 场景文件可能有问题
- 尝试添加测试立方体（见下方"添加测试物体"）

#### ❌ 问题情况2：场景加载失败
```
❌ 加载场景失败: ...
```

**解决方案**：
- 检查场景文件路径和名称
- 确认 `Oldfactory.reality` 文件存在

---

### 步骤2：检查Raycast是否检测到物体

**发射飞剑后，1秒后查看日志：**

#### ✅ 正常情况（检测到物体）：
```
🔍 Raycast调试 (第30帧):
   起点: SIMD3<Float>(0.5, 1.5, -0.5)
   方向: SIMD3<Float>(0.0, -1.0, 0.0)
   长度: 15.23cm
   结果数: 2
   结果[0]: Floor @ 145.50cm, hasCollision=true
   结果[1]: Wall @ 250.00cm, hasCollision=true
```

**关键指标**：
- ✅ `结果数: > 0`
- ✅ `hasCollision=true`

#### ❌ 问题情况1：没有检测到任何物体
```
🔍 Raycast调试 (第30帧):
   起点: SIMD3<Float>(0.5, 1.5, -0.5)
   方向: SIMD3<Float>(0.0, -1.0, 0.0)
   长度: 15.23cm
   结果数: 0
   ⚠️ 没有检测到任何物体！
```

**可能原因**：
1. 射线太短（长度只有15cm）
2. 射线方向不对
3. 场景物体距离太远

**解决方案**：
- 增加射线长度（见下方"调整raycast参数"）
- 检查剑的飞行方向

#### ❌ 问题情况2：检测到物体但没有碰撞组件
```
🔍 Raycast调试:
   结果数: 1
   结果[0]: Floor @ 145.50cm, hasCollision=false  ← 问题！
```

**原因**：该实体没有CollisionComponent

**解决方案**：
- 检查为什么碰撞组件没有添加
- 可能尺寸太小被跳过了

---

### 步骤3：检查碰撞延迟

飞行开始后的前1秒，碰撞检测是禁用的。

**确认延迟后检测开始**：
```
时间 | 日志
-----|------
0.0s | 🚀 发射飞剑
0.5s | （没有Raycast调试输出 - 正常，延迟中）
1.0s | 🔍 Raycast调试 (第30帧) - 开始检测
```

---

## 🛠️ 解决方案

### 方案1：添加测试物体

如果场景没有碰撞组件，添加一个简单的测试立方体：

在 `HandTrackingView.swift` 的 `loadScene` 函数中添加：

```swift
// 添加测试立方体（用于碰撞测试）
let testBox = ModelEntity(
    mesh: .generateBox(size: 1.0),
    materials: [SimpleMaterial(color: .red, isMetallic: false)]
)
testBox.position = [0, 1.0, -2]  // 前方2米，高度1米
testBox.name = "TestCollisionBox"

// 添加碰撞组件
testBox.components.set(CollisionComponent(
    shapes: [.generateBox(size: [1.0, 1.0, 1.0])],
    mode: .default
))

content.add(testBox)
print("✅ 添加测试碰撞立方体: position=\(testBox.position)")
```

**测试**：向测试立方体发射飞剑，应该会碰撞。

---

### 方案2：调整Raycast参数

如果射线太短，增加buffer：

在 `FlyingSwordSystem.swift` 中修改：

```swift
// 当前：
let rayLength = distance + 0.1  // +10cm

// 修改为：
let rayLength = max(distance + 0.5, 1.0)  // 至少1米
```

---

### 方案3：使用generateCollisionShapes

如果场景物体没有碰撞组件，使用RealityKit的自动生成：

在 `HandTrackingView.swift` 的 `loadScene` 中：

```swift
// 方法1：自动生成所有碰撞形状
scene.generateCollisionShapes(recursive: true)
print("✅ 自动生成场景碰撞形状")

// 方法2：手动为场景添加大范围碰撞盒
let groundCollision = CollisionComponent(
    shapes: [.generateBox(size: [100, 0.1, 100])],  // 大地板
    mode: .default
)
let groundEntity = ModelEntity(
    mesh: .generateBox(size: [100, 0.1, 100]),
    materials: [SimpleMaterial(color: .green.withAlphaComponent(0.3), isMetallic: false)]
)
groundEntity.position = [0, 0, 0]
groundEntity.components.set(groundCollision)
content.add(groundEntity)
print("✅ 添加大地板碰撞")
```

---

### 方案4：检查场景文件

如果 `Oldfactory` 场景有问题，临时使用简单场景：

```swift
// 临时：不加载复杂场景，只添加测试物体
func loadScene(in content: any RealityViewContentProtocol) async {
    print("✅ 使用简单测试场景")

    // 添加地板
    let floor = ModelEntity(
        mesh: .generateBox(size: [5, 0.1, 5]),
        materials: [SimpleMaterial(color: .gray, isMetallic: false)]
    )
    floor.position = [0, 0, 0]
    floor.components.set(CollisionComponent(
        shapes: [.generateBox(size: [5, 0.1, 5])],
        mode: .default
    ))
    content.add(floor)

    // 添加墙壁
    let wall = ModelEntity(
        mesh: .generateBox(size: [5, 3, 0.1]),
        materials: [SimpleMaterial(color: .white, isMetallic: false)]
    )
    wall.position = [0, 1.5, -2.5]
    wall.components.set(CollisionComponent(
        shapes: [.generateBox(size: [5, 3, 0.1])],
        mode: .default
    ))
    content.add(wall)

    print("✅ 简单场景创建完成")
}
```

---

## 📊 诊断检查清单

运行应用后，逐项检查：

- [ ] **场景加载成功**
  - 看到 `✅ 场景 'Oldfactory' 加载成功`

- [ ] **碰撞体已添加**
  - `添加碰撞体数: > 0`
  - 看到具体物体名称和尺寸

- [ ] **飞剑发射成功**
  - 看到 `🚀 發射飛劍`
  - 看到 `✅ 飛行中：啟用碰撞檢測`

- [ ] **延迟期结束后开始检测**
  - 飞行1秒后看到 `🔍 Raycast调试`

- [ ] **Raycast检测到物体**
  - `结果数: > 0`
  - `hasCollision=true`

- [ ] **碰撞触发**
  - 看到 `💥 检测到碰撞`
  - 剑停止飞行

---

## 🔬 高级调试

### 打印场景层级结构

```swift
func printSceneHierarchy(_ entity: Entity, depth: Int = 0) {
    let indent = String(repeating: "  ", count: depth)
    print("\(indent)📂 \(entity.name)")
    print("\(indent)   类型: \(type(of: entity))")
    print("\(indent)   位置: \(entity.position(relativeTo: nil))")
    print("\(indent)   子节点数: \(entity.children.count)")

    if let modelEntity = entity as? ModelEntity {
        print("\(indent)   ✅ ModelEntity")
        let hasCollision = modelEntity.components.has(CollisionComponent.self)
        print("\(indent)   碰撞组件: \(hasCollision)")
    }

    for child in entity.children {
        printSceneHierarchy(child, depth: depth + 1)
    }
}

// 在loadScene中调用
printSceneHierarchy(scene)
```

### 可视化Raycast

```swift
// 在场景中绘制射线
func visualizeRaycast(from: SIMD3<Float>, to: SIMD3<Float>, in scene: Scene) {
    let direction = to - from
    let distance = length(direction)
    let midPoint = from + direction * 0.5

    let debugLine = ModelEntity(
        mesh: .generateBox(size: [0.01, 0.01, distance]),
        materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
    )
    debugLine.position = midPoint
    debugLine.look(at: to, from: from, relativeTo: nil)

    scene.addChild(debugLine)

    // 1秒后移除
    Task {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        debugLine.removeFromParent()
    }
}
```

---

## 💡 常见问题

### Q1: 为什么raycast结果数为0？

**A**: 可能原因：
1. 场景物体没有碰撞组件
2. 射线长度太短
3. 射线方向错误
4. 剑飞行方向避开了所有物体

### Q2: 为什么hasCollision=false？

**A**: 该实体没有CollisionComponent，检查：
1. 是否被尺寸过滤跳过了
2. 是否是手部关节或剑
3. 是否不是ModelEntity

### Q3: 如何确认碰撞组件真的添加了？

**A**: 在碰撞体添加后立即验证：

```swift
modelEntity.components.set(collision)
let verified = modelEntity.components.has(CollisionComponent.self)
print("验证碰撞组件: \(verified)")
```

---

## 📝 请提供以下信息

如果问题仍未解决，请提供完整的日志：

1. **场景加载日志**（从 `🔍 开始为场景添加碰撞组件` 到统计结束）
2. **Raycast调试日志**（任意一次 `🔍 Raycast调试` 输出）
3. **碰撞数量**（`添加碰撞体数: X`）
4. **是否使用测试立方体**

有了这些信息，我们可以精确诊断问题！
