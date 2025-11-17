import RealityKit
import Foundation

/// 敵人組件，追蹤敵人的狀態和屬性
struct EnemyComponent: Component {

    // MARK: - 基本屬性

    /// 敵人的最大血量
    var maxHealth: Float = 1.0

    /// 敵人的當前血量
    var currentHealth: Float = 1

    /// 敵人的移動速度 (m/s)
    var moveSpeed: Float = 0.1  // 10cm/s

    /// 敵人是否存活
    var isAlive: Bool {
        return currentHealth > 0
    }

    // MARK: - AI 狀態

    /// 當前目標玩家位置（右手食指指尖）
    var targetPosition: SIMD3<Float>?

    /// 當前速度向量
    var velocity: SIMD3<Float> = .zero

    // MARK: - 初始化

    init(maxHealth: Float = 100.0, moveSpeed: Float = 0.1) {
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        self.moveSpeed = moveSpeed
    }

    // MARK: - 行為方法

    /// 受到傷害
    /// - Parameter damage: 傷害量
    /// - Returns: 敵人是否死亡
    mutating func takeDamage(_ damage: Float) -> Bool {
        currentHealth = max(0, currentHealth - damage)
        print("💔 敵人受到 \(String(format: "%.1f", damage)) 點傷害，剩餘血量: \(String(format: "%.1f", currentHealth))")

        if !isAlive {
            print("💀 敵人死亡！")
            return true
        }
        return false
    }

    /// 計算到目標的方向
    /// - Parameter currentPosition: 當前位置
    /// - Returns: 移動方向（已標準化）
    func calculateDirectionToTarget(from currentPosition: SIMD3<Float>) -> SIMD3<Float>? {
        guard let target = targetPosition else { return nil }

        let direction = target - currentPosition
        let distance = length(direction)

        // 如果距離太近，不移動
        if distance < 0.1 {
            return nil
        }

        return normalize(direction)
    }
}
