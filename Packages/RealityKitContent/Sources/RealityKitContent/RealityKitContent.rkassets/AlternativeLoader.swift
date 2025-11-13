import Foundation
import RealityKit
import RealityKitContent

extension Entity {
    /// 替代的模型加載方法，提供更詳細的錯誤資訊
    static func loadModelWithDetailedLogging(
        named name: String,
        in bundle: Bundle = RealityKitContent.realityKitContentBundle
    ) async throws -> Entity {
        
        print("=== 詳細模型加載診斷 ===")
        print("嘗試載入模型: \(name)")
        print("使用 Bundle: \(bundle.bundlePath)")
        
        // 檢查 bundle 中的所有資源
        if let resourceURLs = bundle.urls(forResourcesWithExtension: nil, subdirectory: nil) {
            print("Bundle 中找到的資源:")
            for url in resourceURLs {
                print("  - \(url.lastPathComponent)")
            }
        }
        
        // 檢查 rkassets 檔案
        if let rkassetsURL = bundle.url(forResource: "RealityKitContent", withExtension: "rkassets") {
            print("找到 RealityKitContent.rkassets 於: \(rkassetsURL)")
        } else {
            print("❌ 未找到 RealityKitContent.rkassets")
        }
        
        // 嘗試不同的載入方法
        do {
            // 方法1: 標準載入
            let entity = try await Entity(named: name, in: bundle)
            print("✅ 成功使用標準方法載入模型")
            return entity
        } catch {
            print("❌ 標準方法失敗: \(error)")
            
            // 方法2: 嘗試使用完整路徑
            do {
                if let rkassetsURL = bundle.url(forResource: "RealityKitContent", withExtension: "rkassets") {
                    let modelURL = rkassetsURL.appendingPathComponent("\(name).usdc")
                    print("嘗試載入完整路徑: \(modelURL)")
                    let entity = try await Entity(contentsOf: modelURL)
                    print("✅ 成功使用完整路徑載入模型")
                    return entity
                }
            } catch {
                print("❌ 完整路徑方法失敗: \(error)")
            }
            
            // 如果所有方法都失敗，重新拋出原始錯誤
            throw error
        }
    }
}