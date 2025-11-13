import RealityKit

/// 遙控參數調整示例
/// 現在所有遙控參數都可以在運行時動態調整！
class RemoteControlManager {
    
    /// 調整特定劍實體的遙控參數
    static func configureSword(entity: Entity,
                               remoteControlStrength: Float = 0.8,
                               fingerInfluenceRatio: Float = 1.0,
                               maxRemoteControlDistance: Float = 20.0,
                               maxVelocityChange: Float = 5.0) {

        guard var swordComponent = entity.components[FlyingSwordComponent.self] else {
            print("❌ 實體沒有 FlyingSwordComponent")
            return
        }

        // 設置動態參數（通過 config）
        swordComponent.config.remoteControlStrength = remoteControlStrength
        swordComponent.config.fingerInfluenceRatio = fingerInfluenceRatio
        swordComponent.config.maxRemoteControlDistance = maxRemoteControlDistance
        swordComponent.config.maxVelocityChange = maxVelocityChange

        // 更新組件
        entity.components[FlyingSwordComponent.self] = swordComponent

        print("✅ 飛劍遙控參數已更新:")
        print("   遙控強度: \(remoteControlStrength)")
        print("   影響比例: \(fingerInfluenceRatio)")
        print("   最大距離: \(maxRemoteControlDistance)m")
        print("   最大速度變化: \(maxVelocityChange)m/s")
    }
    
    /// 預設配置選項
    enum ControlPreset {
        case gentle      // 溫和控制
        case responsive  // 響應式控制  
        case precise     // 精確控制
        case powerful    // 強力控制
        
        var config: (strength: Float, ratio: Float, maxDistance: Float, maxChange: Float) {
            switch self {
            case .gentle:
                return (0.3, 0.5, 1.5, 2.0)
            case .responsive:
                return (0.8, 1.0, 2.0, 5.0)  // 預設值
            case .precise:
                return (0.6, 0.8, 1.0, 3.0)
            case .powerful:
                return (1.0, 2.0, 3.0, 8.0)
            }
        }
    }
    
    /// 應用預設配置
    static func applySwordPreset(entity: Entity, preset: ControlPreset) {
        let config = preset.config
        configureSword(entity: entity,
                      remoteControlStrength: config.strength,
                      fingerInfluenceRatio: config.ratio,
                      maxRemoteControlDistance: config.maxDistance,
                      maxVelocityChange: config.maxChange)
    }
    
    /// 在場景中尋找劍並應用配置
    static func configureAllSwords(in scene: RealityKit.Scene, preset: ControlPreset) {
        if let sword = scene.findEntity(named: "Sword_No1") {
            applySwordPreset(entity: sword, preset: preset)
        }
    }
}

/// 使用示例
func exampleUsage() {
    // 假設你有一個場景引用
    // let scene: RealityKit.Scene = ...
    
    // 方法1: 使用預設配置
    // RemoteControlManager.configureAllSwords(in: scene, preset: .responsive)
    
    // 方法2: 自定義配置  
    // if let sword = scene.findEntity(named: "Sword_No1") {
    //     RemoteControlManager.configureSword(
    //         entity: sword,
    //         remoteControlStrength: 0.9,    // 90% 控制強度
    //         fingerInfluenceRatio: 1.5,     // 1.5倍手指影響
    //         maxRemoteControlDistance: 2.5, // 2.5公尺控制距離
    //         maxVelocityChange: 6.0         // 6m/s 最大速度變化
    //     )
    // }
    
    print("遙控配置示例已準備")
}
