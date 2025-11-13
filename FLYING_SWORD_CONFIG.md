# 飛劍配置系統說明

## 概述

本專案已完成模組化重構，所有飛劍參數現在集中在 `FlyingSwordConfig` 結構體中管理，讓參數調整更加方便且符合 **ECS（Entity Component System）** 架構和 **SRP（單一職責原則）**。

## 架構設計原則

### ECS 架構
- **Entity（實體）**: 劍模型實體
- **Component（組件）**: `FlyingSwordComponent` - 純數據容器，存儲狀態和配置
- **System（系統）**: `FlyingSwordSystem` 和 `HandTrackingSystem` - 處理邏輯

### SRP 原則
- **FlyingSwordConfig**: 只負責配置數據
- **FlyingSwordComponent**: 只負責狀態管理和數據存儲
- **FlyingSwordSystem**: 只負責飛行物理更新
- **HandTrackingSystem**: 只負責手部追蹤和劍的控制

## 檔案結構

```
Mul/Systems/
├── FlyingSwordConfig.swift           # 配置結構體（新增）
├── FlyingSwordComponent.swift        # 組件定義（已重構）
├── FlyingSwordSystem.swift           # 飛行系統（已更新）
├── HandTrackingSystem.swift          # 手部追蹤系統（已更新）
└── FlyingSwordConfigExample.swift    # 使用範例（新增）
```

## 核心文件說明

### 1. FlyingSwordConfig.swift

集中管理所有可調參數，分為以下幾類：

#### 基本物理屬性
- `swordWeight`: 劍的重量（kg）
- `swordLength`: 劍的長度（m）

#### 速度與運動參數
- `velocityThreshold`: 觸發飛行的最小速度
- `velocityMultiplier`: 速度放大倍數
- `minFlyingSpeed`: 最小飛行速度
- `maxFlyingTime`: 最大飛行時間

#### 物理效果參數
- `dragCoefficient`: 空氣阻力係數
- `gravity`: 重力加速度
- `gravityFactor`: 重力影響比例

#### 手部追蹤參數
- `followOffset`: 劍跟隨手指的偏移距離
- `maxHistoryCount`: 位置樣本數量
- `velocityWindow`: 速度計算時間窗口

#### 飛行中遙控參數
- `remoteControlStrength`: 遙控影響強度
- `fingerInfluenceRatio`: 手指影響比例
- `maxRemoteControlDistance`: 最大遙控距離
- `maxVelocityChange`: 最大速度變化量

### 2. 預設配置

系統提供四種預設配置：

#### `.standard` - 標準配置
```swift
FlyingSwordComponent(config: .standard)
```
- 原始設定值
- 適合一般使用

#### `.lightSword` - 輕劍配置
```swift
FlyingSwordComponent(config: .lightSword)
```
- 重量：300g（輕）
- 速度快，遙控靈活
- 更容易觸發，冷卻時間短
- 適合快速戰鬥

#### `.heavySword` - 重劍配置
```swift
FlyingSwordComponent(config: .heavySword)
```
- 重量：800g（重）
- 速度慢，遙控穩定
- 需要更大力道觸發
- 適合重擊戰鬥

#### `.balanced` - 平衡配置
```swift
FlyingSwordComponent(config: .balanced)
```
- 中庸之道
- 啟用物理效果（阻力、重力）
- 適合真實物理體驗

## 使用方法

### 基本使用

在 `HandTrackingSystem.swift` 的 `addJoints` 函數中（約第 320 行）：

```swift
// 使用標準配置
sword.components.set(FlyingSwordComponent(config: .standard))

// 使用輕劍配置
sword.components.set(FlyingSwordComponent(config: .lightSword))

// 使用重劍配置
sword.components.set(FlyingSwordComponent(config: .heavySword))

// 使用平衡配置
sword.components.set(FlyingSwordComponent(config: .balanced))
```

### 自訂配置

```swift
// 方法 1: 基於現有配置修改
var customConfig = FlyingSwordConfig.standard
customConfig.velocityMultiplier = 3.0
customConfig.remoteControlStrength = 2.0
customConfig.dragCoefficient = 0.0
sword.components.set(FlyingSwordComponent(config: customConfig))

// 方法 2: 使用範例工具類
sword.components.set(FlyingSwordConfigExample.createSpeedSword())
sword.components.set(FlyingSwordConfigExample.createControlSword())
sword.components.set(FlyingSwordConfigExample.createRealisticSword())
```

### 運行時調整配置

```swift
// 在遊戲過程中動態調整
if var swordComponent = swordEntity.components[FlyingSwordComponent.self] {
    // 增加速度
    swordComponent.config.velocityMultiplier = 3.0

    // 調整遙控強度
    swordComponent.config.remoteControlStrength = 2.0

    // 更新組件
    swordEntity.components[FlyingSwordComponent.self] = swordComponent
}
```

## 參數調整指南

### 想要劍飛得更快？
```swift
config.velocityMultiplier = 3.0      // 增加速度倍數
config.dragCoefficient = 0.0         // 移除空氣阻力
config.swordWeight = 0.3             // 減輕重量
```

### 想要劍更容易觸發？
```swift
config.velocityThreshold = 0.15      // 降低速度閾值
config.minSamplesForLaunch = 3       // 減少所需樣本數
config.launchCooldown = 0.5          // 縮短冷卻時間
```

### 想要更強的遙控能力？
```swift
config.remoteControlStrength = 2.0   // 增加遙控強度
config.fingerInfluenceRatio = 3.5    // 增加手指影響
config.maxVelocityChange = 25.0      // 允許更大的速度變化
config.maxRemoteControlDistance = 150.0  // 增加遙控距離
```

### 想要更真實的物理？
```swift
config.dragCoefficient = 0.3         // 啟用空氣阻力
config.gravity = -9.8                // 啟用重力
config.gravityFactor = 1.0           // 完整重力影響
config.remoteControlStrength = 0.0   // 關閉遙控
```

### 想要劍飛更久？
```swift
config.maxFlyingTime = 15.0          // 增加最大飛行時間
config.minFlyingSpeed = 0.05         // 降低最小飛行速度
config.dragCoefficient = 0.0         // 移除阻力
```

## 常見使用場景

### 場景 1: 訓練模式
```swift
var trainingConfig = FlyingSwordConfig.lightSword
trainingConfig.velocityThreshold = 0.1     // 極易觸發
trainingConfig.remoteControlStrength = 3.0 // 超強遙控
trainingConfig.maxFlyingTime = 20.0        // 長飛行時間
```

### 場景 2: 競技模式
```swift
var competitiveConfig = FlyingSwordConfig.balanced
competitiveConfig.velocityMultiplier = 2.5
competitiveConfig.remoteControlStrength = 1.0
```

### 場景 3: 寫實模式
```swift
var realisticConfig = FlyingSwordConfig.heavySword
realisticConfig.dragCoefficient = 0.5
realisticConfig.gravity = -9.8
realisticConfig.gravityFactor = 1.0
realisticConfig.remoteControlStrength = 0.2  // 微弱遙控
```

### 場景 4: 特效展示模式
```swift
var showConfig = FlyingSwordConfig.lightSword
showConfig.velocityMultiplier = 5.0        // 超快速度
showConfig.maxFlyingTime = 30.0            // 超長飛行
showConfig.remoteControlStrength = 5.0     // 超強遙控
showConfig.dragCoefficient = 0.0           // 無阻力
showConfig.gravity = 0.0                   // 無重力
```

## 調試技巧

### 列印配置資訊
```swift
FlyingSwordConfigExample.printConfigDetails(
    config: swordComponent.config,
    name: "當前配置"
)
```

### 比較所有預設配置
```swift
FlyingSwordConfigExample.compareAllPresets()
```

### 追蹤配置變化
```swift
print("速度閾值: \(swordComponent.config.velocityThreshold)")
print("遙控強度: \(swordComponent.config.remoteControlStrength)")
print("劍重量: \(swordComponent.config.swordWeight)")
```

## 優勢

### ✅ 模組化
- 所有參數集中管理
- 易於維護和修改

### ✅ 易於調整
- 不需要修改多個文件
- 支持運行時動態調整

### ✅ 符合設計原則
- 遵守 ECS 架構
- 遵守 SRP 原則

### ✅ 擴展性強
- 輕鬆添加新的預設配置
- 支持自訂配置方案

### ✅ 多劍支持
- 每把劍可以有獨立配置
- 輕鬆實現多種劍型

## 進階應用

### 根據玩家等級調整
```swift
func getSwordConfigForLevel(_ level: Int) -> FlyingSwordConfig {
    var config = FlyingSwordConfig.standard
    config.velocityMultiplier = 2.0 + Float(level) * 0.1
    config.remoteControlStrength = 1.0 + Float(level) * 0.05
    return config
}
```

### 技能升級系統
```swift
struct SwordSkillUpgrade {
    static func applyUpgrade(
        config: inout FlyingSwordConfig,
        skill: SkillType
    ) {
        switch skill {
        case .speed:
            config.velocityMultiplier *= 1.2
        case .control:
            config.remoteControlStrength *= 1.3
        case .duration:
            config.maxFlyingTime *= 1.5
        }
    }
}
```

## 疑難排解

### 問題：劍無法觸發
**解決方案**：
- 降低 `velocityThreshold`
- 檢查 `minSamplesForLaunch`
- 確認 `launchCooldown` 不會太長

### 問題：劍遙控不靈敏
**解決方案**：
- 增加 `remoteControlStrength`
- 增加 `fingerInfluenceRatio`
- 增加 `maxVelocityChange`

### 問題：劍飛太快或太慢
**解決方案**：
- 調整 `velocityMultiplier`
- 調整 `dragCoefficient`
- 檢查 `swordWeight`

## 總結

通過這次模組化重構，飛劍系統現在具有：
1. ✅ 集中化的參數管理
2. ✅ 清晰的架構設計
3. ✅ 靈活的配置選項
4. ✅ 易於擴展的框架
5. ✅ 符合 ECS 和 SRP 的最佳實踐

現在你可以輕鬆地調整任何參數，甚至在運行時動態修改配置，為不同的遊戲模式創建不同的劍型！
