# 發射問題診斷指南

## 🔍 問題：劍射不出去

### 調試輸出說明

現在運行應用時，你會看到以下調試信息：

#### 1. 每秒一次的狀態報告
```
🔍 劍狀態: isFlying=false, 樣本數=10
```

**正常狀態**:
- `isFlying=false` - 劍在跟隨模式
- `樣本數` 應該在 5-30 之間變化

#### 2. 樣本收集狀態
```
📈 已收集 10 個位置樣本
📈 已收集 20 個位置樣本
```

**問題診斷**:
- ❌ 如果**從不出現**：樣本沒有被收集（問題A）
- ❌ 如果**卡在某個數字**：樣本收集停止（問題B）
- ✅ 如果**持續增加**：樣本收集正常

#### 3. 發射檢測詳細信息

當你快速揮動手時，應該看到：

```
🎯 檢測速度: 25.34cm/s (閾值: 20.00cm/s)
✅ 速度達標，準備發射！
🚀 發射飛劍！速度: XXX cm/s
```

**可能的失敗原因**:

##### 原因A：樣本不足
```
📊 樣本不足: 3/5
```
**解決**: 等待更長時間再揮動，確保收集足夠樣本

##### 原因B：時間窗口不足
```
⏱️ 時間窗口不足: 0.100/0.150秒
```
**解決**: 樣本收集時間太短，需要更持久的移動

##### 原因C：速度不足
```
🎯 檢測速度: 15.23cm/s (閾值: 20.00cm/s)
```
**解決**: 揮動速度不夠快，需要更快速的動作

##### 原因D：冷卻中
```
⏰ 冷卻中，剩餘: 0.50秒
```
**解決**: 等待冷卻時間結束

---

## 🛠️ 逐步排查

### 步驟1：檢查劍的狀態

運行應用，觀察控制台：

1. **是否看到**：`🔍 劍狀態: isFlying=false, 樣本數=X`？
   - ✅ **是** → 劍的追蹤正常，繼續步驟2
   - ❌ **否** → 劍實體或組件有問題

2. **isFlying 是否一直是 false**？
   - ✅ **是** → 正常，繼續步驟2
   - ❌ **否（一直是true）** → **問題找到！劍卡在飛行狀態**

### 步驟2：檢查樣本收集

1. **是否看到**：`📈 已收集 X 個位置樣本`？
   - ✅ **是** → 樣本收集正常，繼續步驟3
   - ❌ **否** → **問題找到！樣本沒有被收集**

2. **樣本數是否增加**？
   - ✅ **是** → 正常，繼續步驟3
   - ❌ **否** → **問題找到！樣本收集卡住**

### 步驟3：嘗試發射

快速向前揮動手指，觀察輸出：

1. **是否看到任何 shouldLaunch 的輸出**（📊/⏱️/🎯/⏰）？
   - ✅ **是** → 檢測邏輯正常運行，查看具體原因
   - ❌ **否** → **問題找到！shouldLaunch 沒有被調用**

2. **看到什麼失敗原因**？
   - `📊 樣本不足` → 等待更久或降低 `minSamplesForLaunch`
   - `⏱️ 時間窗口不足` → 移動時間更長或降低 `minEffectiveWindow`
   - `🎯 檢測速度: X` (X < 閾值) → 揮動更快或降低 `velocityThreshold`
   - `⏰ 冷卻中` → 等待冷卻時間

---

## 🔧 快速修復方案

### 方案1：降低發射閾值（臨時測試）

如果速度不足，可以臨時降低閾值來測試：

```swift
// 在 FlyingSwordConfig.swift 中修改 .standard 配置
velocityThreshold: 0.1,  // 從 0.2 降低到 0.1
```

### 方案2：減少所需樣本數

```swift
minSamplesForLaunch: 3,  // 從 5 降低到 3
```

### 方案3：縮短時間窗口

```swift
minEffectiveWindow: 0.08,  // 從 0.15 降低到 0.08
```

### 方案4：檢查劍是否卡在飛行狀態

在 HandTrackingSystem 的 update 開始處添加：

```swift
// 臨時重置飛行狀態（僅用於調試）
if var swordComponent = swordEntity.components[FlyingSwordComponent.self] {
    if swordComponent.isFlying {
        print("⚠️ 劍卡在飛行狀態，強制重置")
        swordComponent.resetFlightState()
        swordEntity.components[FlyingSwordComponent.self] = swordComponent
    }
}
```

---

## 🐛 已知可能的Bug

### Bug1：isFlying 卡在 true

**症狀**：
- 控制台顯示 `isFlying=true`
- 永遠看到 `⚠️ 飛行中，不收集樣本`
- 劍無法發射

**原因**：某次飛行後狀態沒有正確重置

**修復**：
1. 檢查 `resetFlightState()` 是否被正確調用
2. 檢查所有 `isFlying = true` 的地方是否有對應的 `isFlying = false`

### Bug2：組件更新沒有寫回

**症狀**：
- 看到樣本收集輸出
- 但樣本數始終顯示為 0 或很小的數字

**原因**：修改了 component 但沒有寫回 entity

**檢查**：
在 HandTrackingSystem.swift 中，確保每次修改後都有：
```swift
swordEntity.components[FlyingSwordComponent.self] = swordComponent
```

### Bug3：速度計算問題

**症狀**：
- 樣本收集正常
- 但速度始終為 0 或非常小

**調試**：
在 `calculateVelocity()` 函數中添加輸出：
```swift
func calculateVelocity() -> SIMD3<Float> {
    guard positionHistory.count >= 2 else {
        print("❌ 樣本太少，無法計算速度")
        return .zero
    }

    // ... 現有代碼 ...

    let positionDelta = lastSample.position - first.position
    let velocity = positionDelta / Float(timeDelta)
    print("🔬 速度計算: delta=\(positionDelta), time=\(timeDelta), vel=\(velocity)")
    return velocity
}
```

---

## 📋 完整診斷流程

運行應用後，執行以下步驟：

1. ⏰ **等待5秒**（讓系統穩定）
2. 👀 **觀察控制台**：應該看到 `🔍 劍狀態` 每秒打印
3. ✋ **靜止持劍30秒**：樣本數應該增加到20-30
4. 💨 **快速揮動**（像投擲一樣）
5. 📊 **查看控制台輸出**：
   - 最理想：`✅ 速度達標，準備發射！` → `🚀 發射飛劍！`
   - 如果失敗：查看具體原因（樣本/時間/速度/冷卻）

---

## 🎯 請回報以下信息

如果仍然無法發射，請提供：

1. **劍狀態輸出**：
   ```
   🔍 劍狀態: isFlying=?, 樣本數=?
   ```

2. **樣本收集是否正常**：
   - 是否看到 `📈 已收集 X 個位置樣本`？
   - 數字是否增加？

3. **揮動時的輸出**：
   - 完整複製揮動時看到的所有輸出

4. **配置信息**：
   - 使用的是哪個配置？（standard/lightSword/heavySword/balanced）

有了這些信息，我們就能精確定位問題！
