/*
Abstract:
The Entry content for a volume.
*/

import SwiftUI
import UIKit

struct Entry: View {
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var chromaKeyColor: Color
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.self) var environment
    let saveAction: ()->Void
    
    let refreshRatesPost20 = ["90", "96", "100"]
    let refreshRatesPre20 = ["90", "96"]
    
    let chromaFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    @State private var chromaRangeMaximum: Float = 1.0
    @State private var newIPAddress: String = ""
    @State private var selectedTab = 0
    
    func applyRangeSettings() {
        if gStore.settings.chromaKeyDistRangeMax < 0.001 {
            gStore.settings.chromaKeyDistRangeMax = 0.001
        }
        if gStore.settings.chromaKeyDistRangeMax > 1.0 {
            gStore.settings.chromaKeyDistRangeMax = 1.0
        }
        if gStore.settings.chromaKeyDistRangeMin < 0.0 {
            gStore.settings.chromaKeyDistRangeMin = 0.0
        }
        if gStore.settings.chromaKeyDistRangeMin > 1.0 {
            gStore.settings.chromaKeyDistRangeMin = 1.0
        }
        
        if gStore.settings.chromaKeyDistRangeMin > gStore.settings.chromaKeyDistRangeMax {
            gStore.settings.chromaKeyDistRangeMin = gStore.settings.chromaKeyDistRangeMax - 0.001
        }
        chromaRangeMaximum = gStore.settings.chromaKeyDistRangeMax
        saveAction()
    }
    
    func applyStreamHz() {
        VideoHandler.applyRefreshRate(videoFormat: EventHandler.shared.videoFormat)
    }
    
    func addNewIPAddress() {
        let trimmedIP = newIPAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedIP.isEmpty && !gStore.settings.savedIPAddresses.contains(trimmedIP) {
            gStore.settings.savedIPAddresses.append(trimmedIP)
            newIPAddress = ""
            saveAction()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Image(.alvrCombinedLogoHqLight)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                
                Spacer()
                
                if eventHandler.alvrVersion != "" {
                    Text(eventHandler.alvrVersion)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            
            // TabView 主内容
            TabView(selection: $selectedTab) {
                // 首页标签
                HomeTab(selectedTab: $selectedTab)
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // 电脑管理标签
                ComputerManagementTab(
                    newIPAddress: $newIPAddress,
                    saveAction: saveAction,
                    addNewIPAddress: addNewIPAddress
                )
                .tabItem {
                    Label("电脑管理", systemImage: "desktopcomputer")
                }
                .tag(1)
                
                // 设置标签
                SettingsTab(
                    chromaKeyColor: $chromaKeyColor,
                    chromaRangeMaximum: chromaRangeMaximum,
                    saveAction: saveAction,
                    applyStreamHz: applyStreamHz,
                    applyRangeSettings: applyRangeSettings
                )
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: 1280, maxWidth: 1280, minHeight: 720, maxHeight: 720)
        .glassBackgroundEffect()
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                saveAction()
                break
            case .inactive:
                saveAction()
                break
            case .active:
                break
            @unknown default:
                break
            }
        }
        .task({
            applyRangeSettings()
        })
    }
}

// 首页标签视图
struct HomeTab: View {
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部状态栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ALVR")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("中文版 V.\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "20.13.01")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
            Spacer()
                
                // 连接状态指示器
                HStack(spacing: 12) {
                    Circle()
                        .fill(eventHandler.connectionState == .connected ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    
                    Text(eventHandler.connectionState == .connected ? "已连接" : "未连接")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(eventHandler.connectionState == .connected ? .green : .gray)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            
            // 主要内容区域
            VStack(spacing: 40) {
                Spacer()
                
                // 连接状态卡片
                VStack(spacing: 20) {
                if eventHandler.connectionState == .connected {
                    // 已连接状态 - 开始游玩按钮
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 12) {
                            Text("连接成功")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if eventHandler.hostname != "" {
                                Text(eventHandler.hostname)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            if eventHandler.IP != "" {
                                Text(eventHandler.IP)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 开始游玩按钮
                        Button(action: {
                            // 这里可以添加开始串流的逻辑
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20))
                                Text("开始游玩")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    // 未连接状态 - vision.pro.slash 图标 + 配对提示
                    VStack(spacing: 20) {
                        Image(systemName: "vision.pro.slash")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("没绑定电脑")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Text("去电脑ALVR app配对或者是在")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                Button("这里") {
                                    selectedTab = 1 // 切换到电脑管理页面
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                
                                Text("配对")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                     // 连接状态文本
                if eventHandler.connectionFlavorText != "" {
                    Text(eventHandler.connectionFlavorText)
                            .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
            
            // 开始/停止按钮（仅在未连接时显示）
            if eventHandler.connectionState != .connected {
                EntryControls(saveAction: {})
                    .padding(.top, 20)
            }
            
            Spacer()
            
                // 底部信息
            if eventHandler.connectionState == .connected && eventHandler.hostAlvrVersion != "" {
                    VStack(spacing: 8) {
                    Text("流媒体服务器版本: \(eventHandler.hostAlvrVersion)")
                            .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("客户端协议: \(eventHandler.getMdnsProtocolId())")
                            .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.bottom, 30)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// 电脑管理标签视图
struct ComputerManagementTab: View {
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var newIPAddress: String
    let saveAction: ()->Void
    let addNewIPAddress: ()->Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的电脑")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("管理您的电脑连接")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 添加按钮
                Button(action: {
                    // 这里可以添加一个弹出式添加界面
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("添加电脑")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            
            // 主要内容
            VStack(spacing: 30) {
                // 添加新IP部分
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        Text("添加新电脑")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(spacing: 12) {
                HStack {
                    TextField("输入IP地址 (例如: 192.168.1.100)", text: $newIPAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                    
                    Button("添加") {
                        addNewIPAddress()
                    }
                    .disabled(newIPAddress.isEmpty || gStore.settings.savedIPAddresses.contains(newIPAddress))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(newIPAddress.isEmpty || gStore.settings.savedIPAddresses.contains(newIPAddress) ? Color.gray : Color.blue)
                            .cornerRadius(8)
                        }
                        
                        Text("去电脑 ALVR App 信任您的Vision Pro或输入IP来配对")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
            
            // 电脑列表
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        Text("已添加的电脑")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    if gStore.settings.savedIPAddresses.isEmpty && eventHandler.connectionState != .connected {
                        // 空状态
                        VStack(spacing: 16) {
                            Image(systemName: "desktopcomputer")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            VStack(spacing: 8) {
                                Text("没有添加电脑")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("点击上方\"添加电脑\"按钮来添加您的第一台电脑")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    } else {
                        // 电脑列表
                        LazyVStack(spacing: 12) {
                        // 显示自动发现的电脑（如果已连接）
                        if eventHandler.connectionState == .connected && eventHandler.IP != "" {
                            ComputerRow(
                                name: eventHandler.hostname,
                                ip: eventHandler.IP,
                                isConnected: true,
                                isSelected: gStore.settings.currentSelectedIP == eventHandler.IP,
                                isAutoDiscovered: true
                            ) {
                                gStore.settings.currentSelectedIP = eventHandler.IP
                                saveAction()
                            } onDelete: {
                                // 自动发现的不能删除
                            }
                        }
                        
                        // 显示手动添加的IP
                        ForEach(gStore.settings.savedIPAddresses, id: \.self) { ip in
                            ComputerRow(
                                name: "手动添加",
                                ip: ip,
                                isConnected: eventHandler.IP == ip && eventHandler.connectionState == .connected,
                                isSelected: gStore.settings.currentSelectedIP == ip,
                                isAutoDiscovered: false
                            ) {
                                gStore.settings.currentSelectedIP = ip
                                saveAction()
                            } onDelete: {
                                if let index = gStore.settings.savedIPAddresses.firstIndex(of: ip) {
                                    gStore.settings.savedIPAddresses.remove(at: index)
                                    if gStore.settings.currentSelectedIP == ip {
                                        gStore.settings.currentSelectedIP = ""
                                    }
                                    saveAction()
                                }
                            }
                        }
                    }
                }
            }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

// 电脑行视图
struct ComputerRow: View {
    let name: String
    let ip: String
    let isConnected: Bool
    let isSelected: Bool
    let isAutoDiscovered: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
            Button(action: onSelect) {
            HStack(spacing: 16) {
                // 状态图标
                VStack(spacing: 4) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .blue : .secondary)
                    
                    if isConnected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // 电脑信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                            Text(name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            
                            if isAutoDiscovered {
                                Text("自动发现")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(6)
                            }
                            
                            if isConnected {
                                Text("已连接")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(ip)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            
            // 删除按钮（仅手动添加的可删除）
            if !isAutoDiscovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                            .font(.system(size: 16))
                        .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// 设置标签视图
struct SettingsTab: View {
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var chromaKeyColor: Color
    let chromaRangeMaximum: Float
    let saveAction: ()->Void
    let applyStreamHz: ()->Void
    let applyRangeSettings: ()->Void
    
    let refreshRatesPost20 = ["90", "96", "100"]
    let refreshRatesPre20 = ["90", "96"]
    
    let chromaFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
                        HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("设置和配置")
                        .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            
            // 主要内容
            ScrollView {
                VStack(spacing: 24) {
                    // 设置选项
                    VStack(spacing: 16) {
                        // 设置选项
                        SettingsRow(
                            icon: "gear",
                            title: "设置",
                            subtitle: "基础配置选项",
                            action: {
                                // 这里可以添加设置页面导航
                            }
                        )
                        
                        SettingsRow(
                            icon: "gearshape.2",
                            title: "高级设置",
                            subtitle: "实验性功能和高级选项",
                            action: {
                                // 这里可以添加高级设置页面导航
                            }
                        )
                        
                        SettingsRow(
                            icon: "info.circle",
                            title: "关于",
                            subtitle: "版本信息和帮助",
                            action: {
                                // 这里可以添加关于页面导航
                            }
                        )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    
                    // 版本信息
                    VStack(spacing: 12) {
                        Text("ALVR中文版 V.\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "20.13.01")")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("基于原ALVR项目改进遵主MIT用户协议")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
}

// 设置行视图
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
