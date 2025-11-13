import RealityKit
import ARKit

/// 追蹤飛劍狀態的組件
/// 遵守 ECS 原則：純數據容器 + 狀態管理
struct FlyingSwordComponent: Component {

    // MARK: - 配置

    /// 飛劍配置（可在初始化時指定不同的配置方案）
    var config: FlyingSwordConfig

    // MARK: - 飛行狀態

    /// 劍是否正在飛行中
    var isFlying: Bool = false

    /// 劍釋放時的速度 (m/s)
    var velocity: SIMD3<Float> = .zero

    /// 累積飛行時間（秒），使用逐幀 deltaTime
    var elapsedTime: TimeInterval = 0

    /// 最後一次發射的時間戳（系統運行時間）；0 表示尚未發射過
    var lastLaunchTimestamp: TimeInterval = 0

    /// 發射時劍的初始方向（用於平滑轉向）
    var launchInitialDirection: SIMD3<Float>?

    /// 是否處於發射轉向階段
    var isLaunchTurning: Bool = false

    /// 是否處於自動返回轉向階段
    var isAutoReturnTurning: Bool = false

    // MARK: - 召回手勢追蹤

    /// 捏合手勢按壓開始時間（系統運行時間）；0 表示未按壓
    var pinchPressStartTime: TimeInterval = 0

    /// 是否正在進行捏合按壓
    var isPinchPressed: Bool = false

    // MARK: - 位置追蹤歷史

    /// 用於速度計算的位置歷史記錄
    var positionHistory: [(position: SIMD3<Float>, timestamp: TimeInterval)] = []

    /// 飛行中的手指位置歷史記錄（用於計算遙控輸入）
    var fingerPositionHistory: [(position: SIMD3<Float>, timestamp: TimeInterval)] = []

    /// 上一幀的劍尖世界座標位置（用於精確碰撞檢測）
    var lastTipWorld: SIMD3<Float>? = nil

    /// 質心到劍尖的距離（根據劍的實際長度，約為長度的一半）
    var swordTipOffset: Float {
        return config.swordLength / 2.0  // 0.8m / 2 = 0.4m
    }

    // MARK: - 初始化

    /// 使用指定配置初始化
    init(config: FlyingSwordConfig = .standard) {
        self.config = config
    }

    // MARK: - 位置樣本管理

    /// 將位置樣本加入歷史記錄
    mutating func addPositionSample(position: SIMD3<Float>, timestamp: TimeInterval) {
        // 飛行中不收集樣本
        if isFlying { return }

        // 強制執行樣本間的最小間隔時間，避免重複或接近重複的時間戳
        if let last = positionHistory.last,
           (timestamp - last.timestamp) < config.minSampleInterval {
            return
        }

        positionHistory.append((position, timestamp))

        // 保持最近的樣本數量在容量限制內
        if positionHistory.count > config.maxHistoryCount {
            positionHistory.removeFirst()
        }

        // 同時按時間窗口修剪，只保留最近的數據
        trimHistory(to: config.velocityWindow, latestTimestamp: timestamp)
    }

    /// 飛行中添加手指位置樣本（用於遙控）
    mutating func addFingerPositionSample(position: SIMD3<Float>, timestamp: TimeInterval) {
        // 只在飛行中才收集手指位置
        guard isFlying else { return }

        // 強制執行樣本間的最小間隔時間
        if let last = fingerPositionHistory.last,
           (timestamp - last.timestamp) < config.minFingerSampleInterval {
            return
        }

        fingerPositionHistory.append((position, timestamp))

        // 保持最近的樣本數量在容量限制內
        if fingerPositionHistory.count > config.maxFingerHistoryCount {
            fingerPositionHistory.removeFirst()
        }
    }

    /// 修剪歷史記錄，只保留在指定時間窗口內且以 latestTimestamp 為結束點的樣本
    private mutating func trimHistory(to window: TimeInterval, latestTimestamp: TimeInterval) {
        while let first = positionHistory.first,
              (latestTimestamp - first.timestamp) > window {
            positionHistory.removeFirst()
        }
    }

    // MARK: - 速度計算

    /// 根據最近的位置歷史記錄計算當前速度
    func calculateVelocity() -> SIMD3<Float> {
        guard positionHistory.count >= 2 else { return .zero }

        guard let last = positionHistory.last else { return .zero }
        let cutoff = last.timestamp - config.velocityWindow
        let windowed = positionHistory.drop { $0.timestamp < cutoff }

        guard windowed.count >= 2,
              let first = windowed.first,
              let lastSample = windowed.last else {
            return .zero
        }

        let timeDelta = lastSample.timestamp - first.timestamp
        guard timeDelta >= config.minEffectiveWindow else {
            return .zero
        }

        let positionDelta = lastSample.position - first.position
        return positionDelta / Float(timeDelta)
    }

    /// 計算手指移動的速度（用於飛行中的遙控）
    func calculateFingerVelocity() -> SIMD3<Float> {
        guard fingerPositionHistory.count >= 2,
              let first = fingerPositionHistory.first,
              let last = fingerPositionHistory.last else {
            return .zero
        }

        let timeDelta = last.timestamp - first.timestamp
        guard timeDelta > 0 else { return .zero }

        let positionDelta = last.position - first.position
        return positionDelta / Float(timeDelta)
    }

    // MARK: - 發射邏輯

    /// 檢查當前速度是否超過閾值
    mutating func shouldLaunch() -> Bool {
        // 冷卻時間檢查
        let now = ProcessInfo.processInfo.systemUptime
        if lastLaunchTimestamp > 0,
           (now - lastLaunchTimestamp) < config.launchCooldown {
            return false
        }

        // 樣本數檢查
        if positionHistory.count < config.minSamplesForLaunch {
            return false
        }

        // 窗口時間檢查
        guard let first = positionHistory.first,
              let last = positionHistory.last else {
            return false
        }
        let timeWindow = last.timestamp - first.timestamp
        if timeWindow < config.minEffectiveWindow {
            return false
        }

        let velocity = calculateVelocity()
        let speed = length(velocity)

        if speed > config.velocityThreshold {
            lastLaunchTimestamp = now
            print("✅ 速度達標: \(String(format: "%.2f", speed * 100))cm/s，準備發射！")
            return true
        }
        return false
    }

    /// 計算發射時的修正速度（考慮重量、力度等因素）
    func calculateLaunchVelocity() -> SIMD3<Float> {
        let baseVelocity = calculateVelocity()

        // 應用速度放大倍數
        var launchVelocity = baseVelocity * config.velocityMultiplier

        // 根據劍的重量調整（重劍需要更多力量才能達到相同速度）
        let weightFactor = 1.0 / (1.0 + config.swordWeight * 0.5)
        launchVelocity *= weightFactor

        return launchVelocity
    }

    // MARK: - 遙控邏輯

    /// 計算遙控對飛劍速度的影響
    mutating func calculateRemoteControlVelocityChange(swordPosition: SIMD3<Float>) -> SIMD3<Float> {
        guard isFlying else { return .zero }

        // ⭐ 新增：如果正在捏合且在0-0.5秒階段，禁用遙控
        if isPinchPressed {
            let currentTime = ProcessInfo.processInfo.systemUptime
            let pressDuration = currentTime - pinchPressStartTime
            if pressDuration < 0.5 {
                return .zero  // 禁用遙控，讓右手可以回到身體中間
            }
        }

        let fingerVelocity = calculateFingerVelocity()

        // 如果手指速度太小，不施加影響
        if length(fingerVelocity) < 0.1 { return .zero }

        // 計算手指到劍的距離，距離越遠影響力越小
        guard let lastFingerPos = fingerPositionHistory.last?.position else {
            return .zero
        }
        let distance = length(swordPosition - lastFingerPos)
        let distanceFactor = max(0, 1 - (distance / config.maxRemoteControlDistance))

        // 計算最終的速度變化
        var velocityChange = fingerVelocity
            * config.fingerInfluenceRatio
            * config.remoteControlStrength
            * distanceFactor

        // 限制最大變化量，防止劇烈變化
        let changeLength = length(velocityChange)
        if changeLength > config.maxVelocityChange {
            velocityChange = normalize(velocityChange) * config.maxVelocityChange
        }

        return velocityChange
    }

    // MARK: - 狀態重置

    /// 重置飛行狀態（包括清理手指位置歷史）
    mutating func resetFlightState() {
        isFlying = false
        velocity = .zero
        elapsedTime = 0
        launchInitialDirection = nil
        isLaunchTurning = false
        isAutoReturnTurning = false
        pinchPressStartTime = 0
        isPinchPressed = false
        positionHistory.removeAll(keepingCapacity: true)
        fingerPositionHistory.removeAll(keepingCapacity: true)
        lastTipWorld = nil  // 清除剑尖位置缓存
    }
}
