import SwiftUI

/// GM 風格的遊戲設定介面
/// 支援分頁式設定管理，精確數值調整
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = GameSettings.shared
    @State private var selectedTab: SettingsTab = .swordControl

    enum SettingsTab: String, CaseIterable {
        case swordControl = "飛劍手感"
        case physics = "物理參數"
        case enemy = "敵人設定"
        case visual = "視覺效果"
        case debug = "調試選項"

        var icon: String {
            switch self {
            case .swordControl: return "hand.point.up.left.fill"
            case .physics: return "atom"
            case .enemy: return "figure.walk"
            case .visual: return "eye.fill"
            case .debug: return "wrench.and.screwdriver.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 左側分頁選單
                sidebarView

                Divider()

                // 右側內容區
                contentView
            }
            .navigationTitle("遊戲設定 (GM)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("預設模板", systemImage: "folder.fill") {
                        ForEach(GameSettings.SwordPreset.allCases, id: \.self) { preset in
                            Button(preset.rawValue) {
                                settings.applySwordPreset(preset)
                            }
                        }
                        Divider()
                        Button("重置所有設定", role: .destructive) {
                            settings.resetToDefaults()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - 側邊欄
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.icon)
                            .frame(width: 24)
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        Color.accentColor.opacity(0.15) :
                        Color.clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding()
        .frame(width: 220)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 內容區
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch selectedTab {
                case .swordControl:
                    swordControlSection
                case .physics:
                    physicsSection
                case .enemy:
                    enemySection
                case .visual:
                    visualSection
                case .debug:
                    debugSection
                }
            }
            .padding(24)
        }
    }

    // MARK: - 飛劍手感設定
    private var swordControlSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("發射觸發", icon: "paperplane.fill")

            ParameterRow(
                label: "速度閾值",
                value: $settings.velocityThreshold,
                range: 0.1...1.0,
                step: 0.05,
                unit: "m/s",
                description: "觸發飛行所需的最小速度"
            )

            ParameterRow(
                label: "速度倍數",
                value: $settings.velocityMultiplier,
                range: 1.0...10.0,
                step: 0.5,
                unit: "x",
                description: "投擲速度放大倍數"
            )

            ParameterRow(
                label: "最小飛行速度",
                value: $settings.minFlyingSpeed,
                range: 0.5...5.0,
                step: 0.1,
                unit: "m/s",
                description: "飛劍的最低飛行速度"
            )

            ParameterRow(
                label: "發射冷卻",
                value: $settings.launchCooldown,
                range: 0.1...2.0,
                step: 0.1,
                unit: "秒",
                description: "發射後的冷卻時間"
            )

            Divider()

            sectionHeader("遙控參數", icon: "hand.draw.fill")

            ParameterRow(
                label: "遙控強度",
                value: $settings.remoteControlStrength,
                range: 0.0...3.0,
                step: 0.1,
                unit: "",
                description: "手指移動對飛劍的影響強度"
            )

            ParameterRow(
                label: "手指影響比例",
                value: $settings.fingerInfluenceRatio,
                range: 0.5...5.0,
                step: 0.1,
                unit: "",
                description: "手指移動速度轉換為飛劍速度的比例"
            )

            ParameterRow(
                label: "最大遙控距離",
                value: $settings.maxRemoteControlDistance,
                range: 10.0...200.0,
                step: 10.0,
                unit: "米",
                description: "超過此距離遙控失效"
            )

            ParameterRow(
                label: "最大速度變化",
                value: $settings.maxVelocityChange,
                range: 1.0...10.0,
                step: 0.5,
                unit: "m/s",
                description: "遙控時每幀最大速度改變量"
            )

            Divider()

            sectionHeader("轉向與召回", icon: "arrow.uturn.left.circle.fill")

            ParameterRow(
                label: "召回轉向速度",
                value: $settings.recallTurnSpeed,
                range: 1.0...10.0,
                step: 0.5,
                unit: "rad/s",
                description: "召回時的轉向靈敏度"
            )

            ParameterRow(
                label: "發射轉向速度",
                value: $settings.launchTurnSpeed,
                range: 1.0...10.0,
                step: 0.5,
                unit: "rad/s",
                description: "發射時的轉向靈敏度"
            )

            ParameterRow(
                label: "發射轉向時長",
                value: $settings.launchTurnDuration,
                range: 0.1...1.0,
                step: 0.05,
                unit: "秒",
                description: "發射後保持轉向的時間"
            )

            ParameterRow(
                label: "自動返回轉向速度",
                value: $settings.autoReturnTurnSpeed,
                range: 1.0...10.0,
                step: 0.5,
                unit: "rad/s",
                description: "自動返回時的轉向靈敏度"
            )

            ParameterRow(
                label: "召回初始速度",
                value: $settings.recallSpeed,
                range: 0.5...5.0,
                step: 0.1,
                unit: "m/s",
                description: "召回開始時的速度"
            )

            ParameterRow(
                label: "召回最大速度",
                value: $settings.maxRecallSpeed,
                range: 1.0...10.0,
                step: 0.5,
                unit: "m/s",
                description: "召回加速到的最大速度"
            )

            ParameterRow(
                label: "加速達最大速度時間",
                value: $settings.maxRecallSpeedTime,
                range: 1.0...10.0,
                step: 0.5,
                unit: "秒",
                description: "召回從初始速度加速到最大速度所需時間"
            )

            Divider()

            sectionHeader("跟隨參數", icon: "hand.point.up.left")

            ParameterRow(
                label: "跟隨偏移距離",
                value: $settings.followOffset,
                range: 0.05...0.5,
                step: 0.01,
                unit: "米",
                description: "劍跟隨手指時的距離偏移"
            )
        }
    }

    // MARK: - 物理參數設定
    private var physicsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("劍的物理屬性", icon: "scalemass.fill")

            ParameterRow(
                label: "劍的重量",
                value: $settings.swordWeight,
                range: 0.1...2.0,
                step: 0.1,
                unit: "kg",
                description: "影響動能傷害和發射速度"
            )

            ParameterRow(
                label: "劍的長度",
                value: $settings.swordLength,
                range: 0.5...1.5,
                step: 0.05,
                unit: "米",
                description: "影響劍尖偏移和碰撞範圍"
            )

            Divider()

            sectionHeader("運動物理", icon: "arrow.down.circle.fill")

            ParameterRow(
                label: "阻力係數",
                value: $settings.dragCoefficient,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "空氣阻力，0=無阻力"
            )

            ParameterRow(
                label: "重力",
                value: $settings.gravity,
                range: 0.0...9.8,
                step: 0.5,
                unit: "m/s²",
                description: "重力加速度，0=無重力"
            )

            ParameterRow(
                label: "重力影響因子",
                value: $settings.gravityFactor,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "實際重力影響的百分比"
            )

            Divider()

            sectionHeader("碰撞物理", icon: "circle.hexagonpath.fill")

            ParameterRow(
                label: "靜摩擦係數",
                value: $settings.staticFriction,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "靜止時的摩擦力"
            )

            ParameterRow(
                label: "動摩擦係數",
                value: $settings.dynamicFriction,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "運動時的摩擦力"
            )

            ParameterRow(
                label: "彈性係數",
                value: $settings.restitution,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "碰撞反彈強度，0=不反彈，1=完全彈性"
            )
        }
    }

    // MARK: - 敵人設定
    private var enemySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("生成設定", icon: "timer")

            ParameterRow(
                label: "生成間隔",
                value: $settings.enemySpawnInterval,
                range: 1.0...30.0,
                step: 1.0,
                unit: "秒",
                description: "每隔多久生成一個敵人"
            )

            ParameterRow(
                label: "生成區域大小",
                value: $settings.enemySpawnAreaSize,
                range: 10.0...100.0,
                step: 5.0,
                unit: "米",
                description: "敵人生成的區域範圍（正方形）"
            )

            ParameterRow(
                label: "玩家排除半徑",
                value: $settings.enemyPlayerExclusionRadius,
                range: 5.0...30.0,
                step: 1.0,
                unit: "米",
                description: "玩家周圍不生成敵人的距離"
            )

            Divider()

            sectionHeader("敵人屬性", icon: "figure.walk")

            ParameterRow(
                label: "最大血量",
                value: $settings.enemyMaxHealth,
                range: 10.0...1000.0,
                step: 10.0,
                unit: "HP",
                description: "敵人的血量"
            )

            ParameterRow(
                label: "移動速度",
                value: $settings.enemyMoveSpeed,
                range: 0.01...1.0,
                step: 0.01,
                unit: "m/s",
                description: "敵人移動速度"
            )

            ParameterRow(
                label: "縮放比例",
                value: $settings.enemyScale,
                range: 0.5...20.0,
                step: 0.5,
                unit: "x",
                description: "敵人模型的大小"
            )

            Divider()

            sectionHeader("傷害與碰撞", icon: "burst.fill")

            ParameterRow(
                label: "傷害倍數",
                value: $settings.enemyDamageMultiplier,
                range: 1.0...50.0,
                step: 1.0,
                unit: "x",
                description: "動能轉傷害的倍數（1焦耳 = N點傷害）"
            )

            ParameterRow(
                label: "碰撞檢測半徑",
                value: $settings.enemyCollisionRadius,
                range: 0.5...5.0,
                step: 0.05,
                unit: "米",
                description: "飛劍與敵人的碰撞檢測範圍"
            )
        }
    }

    // MARK: - 視覺效果設定
    private var visualSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("傷害數字", icon: "textformat.123")

            ParameterRow(
                label: "字體大小",
                value: $settings.damageFontSize,
                range: 0.1...2.0,
                step: 0.05,
                unit: "",
                description: "傷害數字的大小"
            )

            ParameterRow(
                label: "飄動速度",
                value: $settings.damageFloatSpeed,
                range: 0.1...3.0,
                step: 0.1,
                unit: "m/s",
                description: "傷害數字向上飄動的速度"
            )

            ParameterRow(
                label: "淡出時間",
                value: $settings.damageFadeDuration,
                range: 0.5...5.0,
                step: 0.1,
                unit: "秒",
                description: "傷害數字淡出消失的時間"
            )

            ParameterRow(
                label: "初始高度偏移",
                value: $settings.damageInitialOffsetY,
                range: 0.0...1.0,
                step: 0.05,
                unit: "米",
                description: "傷害數字初始位置向上偏移"
            )

            Divider()

            sectionHeader("動態效果", icon: "speedometer")

            ParameterRow(
                label: "速度影響飄動",
                value: $settings.damageSpeedInfluenceOnFloatSpeed,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "飛劍速度對飄動速度的影響（0-1）"
            )

            ParameterRow(
                label: "速度影響持續時間",
                value: $settings.damageSpeedInfluenceOnDuration,
                range: 0.0...1.0,
                step: 0.05,
                unit: "",
                description: "飛劍速度對顯示時間的影響（0-1）"
            )
        }
    }

    // MARK: - 調試選項
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("可視化", icon: "eye.fill")

            Toggle(isOn: $settings.showCollisionBox) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("顯示碰撞箱")
                        .font(.system(size: 16, weight: .medium))
                    Text("顯示敵人的碰撞箱線框")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            Divider()

            sectionHeader("日誌", icon: "doc.text.fill")

            Toggle(isOn: $settings.enableDebugLogs) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("啟用調試日誌")
                        .font(.system(size: 16, weight: .medium))
                    Text("在控制台輸出詳細的調試信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - 輔助視圖
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.top, 8)
    }
}

// MARK: - 參數調整行
struct ParameterRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let description: String

    @State private var isEditing = false
    @State private var textValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題行
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                valueDisplay
            }

            // 滑桿
            HStack(spacing: 12) {
                Text(String(format: "%.2f", range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)

                Slider(value: $value, in: range, step: step)

                Text(String(format: "%.2f", range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            // 說明文字
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var valueDisplay: some View {
        HStack(spacing: 4) {
            if isEditing {
                TextField("", text: $textValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .keyboardType(.decimalPad)
                    .onAppear {
                        textValue = String(format: "%.2f", value)
                    }
                    .onSubmit {
                        if let newValue = Double(textValue) {
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        isEditing = false
                    }
            } else {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .onTapGesture {
                        isEditing = true
                    }
            }
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(minWidth: 30, alignment: .leading)
        }
        .frame(width: 140, alignment: .trailing)
    }
}

#Preview {
    SettingsView()
}
