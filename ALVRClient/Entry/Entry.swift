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
    @State private var showOriginalStatus = false
    
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
            // TabView 主内容
            TabView(selection: $selectedTab) {
                // 首页标签
                HomeTab(selectedTab: $selectedTab, showOriginalStatus: $showOriginalStatus)
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
                
                // 我的标签
                SettingsTab(
                    chromaKeyColor: $chromaKeyColor,
                    chromaRangeMaximum: chromaRangeMaximum,
                    saveAction: saveAction,
                    applyStreamHz: applyStreamHz,
                    applyRangeSettings: applyRangeSettings
                )
                .tabItem {
                    Label("我的", systemImage: "person.circle.fill")
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
    @Binding var showOriginalStatus: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // ALVR Logo 和版本信息
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
            
            // 顶部状态栏
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eventHandler.connectionState == .connected ? "已连接" : "未连接")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(eventHandler.connectionState == .connected ? .green : .gray)
                        
                        if !eventHandler.connectionFlavorText.isEmpty {
                            Text(showOriginalStatus ? eventHandler.connectionFlavorText : translateStatusMessage(eventHandler.connectionFlavorText))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            
            // 主要内容区域
            VStack(spacing: 40) {
                Spacer()
                
                // 连接状态卡片
                Group {
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
                                    
                                    Text("这里")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                        .underline()
                                        .onTapGesture {
                                            selectedTab = 1 // 切换到电脑管理页面
                                        }
                                    
                                    Text("配对")
                                        .font(.system(size: 16))
                            .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
            
            Spacer()
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
    @State private var selectedComputer: String? = nil
    @State private var showingAddComputer = false
    let saveAction: ()->Void
    let addNewIPAddress: ()->Void
    
    var body: some View {
        NavigationSplitView {
            // 左侧栏 - 电脑选择
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Text("电脑管理")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 添加按钮
                    Button(action: {
                        showingAddComputer = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemBackground))
            
            // 电脑列表
                if gStore.settings.savedIPAddresses.isEmpty && eventHandler.connectionState != .connected {
                    // 没有电脑时的状态
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "macbook.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("没有绑定任何一台电脑")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("请去上方搜索IP地址或者打开电脑端ALVR app自动配对连接")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 有电脑时的列表
                    List {
                        // 显示自动发现的电脑（如果已连接）
                        if eventHandler.connectionState == .connected && eventHandler.IP != "" {
                            Section("自动发现") {
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
                        }
                        
                        // 显示手动添加的IP
                        if !gStore.settings.savedIPAddresses.isEmpty {
                            Section("手动添加") {
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
                    .listStyle(.plain)
                }
            }
            .navigationTitle("电脑管理")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            // 右侧栏 - 详情视图
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "macbook.and.vision.pro")
                    .font(.system(size: 120))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("与您的电脑一起玩VR")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("选择左侧的电脑开始连接")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
        .sheet(isPresented: $showingAddComputer) {
            AddComputerSheet(
                newIPAddress: $newIPAddress,
                addNewIPAddress: addNewIPAddress,
                isPresented: $showingAddComputer
            )
        }
    }
}

// 添加电脑的弹出式界面
struct AddComputerSheet: View {
    @Binding var newIPAddress: String
    let addNewIPAddress: ()->Void
    @Binding var isPresented: Bool
    @EnvironmentObject var gStore: GlobalSettingsStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("添加新电脑")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("输入电脑的IP地址进行连接")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    TextField("输入IP地址 (例如: 192.168.1.100)", text: $newIPAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16))
                    
                    Text("去电脑 ALVR App 信任您的Vision Pro或输入IP来配对")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("添加电脑")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("添加") {
                    addNewIPAddress()
                    isPresented = false
                }
                .disabled(newIPAddress.isEmpty || gStore.settings.savedIPAddresses.contains(newIPAddress))
            )
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

// 我的标签视图
struct SettingsTab: View {
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var chromaKeyColor: Color
    let chromaRangeMaximum: Float
    let saveAction: ()->Void
    let applyStreamHz: ()->Void
    let applyRangeSettings: ()->Void
    @State private var showOriginalStatus = false
    @State private var showingAdvancedSettings = false
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var csaHostID: String = ""
    @State private var isCSALoggedIn: Bool = false
    @State private var csaAccountName: String = ""
    
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
                }
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 25)

            // 主要内容只保留菜单卡片，增加水平padding和字体大小
        ScrollView {
                VStack(spacing: 12) {
                    // 菜单卡片（设置 / 高级设置 / 关于 / 开源代码许可）
                    VStack(spacing: 0) {
                        Button {
                            showingAdvancedSettings = false
                            showingSettings = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "gear")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("设置")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        Button {
                            showingSettings = false
                            showingAdvancedSettings = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("高级设置")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        Button {
                            showingSettings = false
                            showingAdvancedSettings = false
                            showingAbout = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("关于")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)

                        
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 200)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedSettingsView(
                chromaKeyColor: $chromaKeyColor,
                saveAction: saveAction,
                chromaFormatter: chromaFormatter,
                onClose: { showingAdvancedSettings = false }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(saveAction: saveAction)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// 关于视图（关于与开源许可合并）
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ALVR")
                        .font(.system(size: 22, weight: .bold))
                    Text("由 @alvr-org 制作")
                    if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("版本：\(v)")
                    }
                    Text("汉化：@caidingding233")
                    Link("作者项目主页（alvr-org）", destination: URL(string: "https://github.com/alvr-org/ALVR")!)
                    Link("安装指南", destination: URL(string: "https://github.com/alvr-org/ALVR/wiki/Installation-guide")!)
                    Link("问题排查", destination: URL(string: "https://github.com/alvr-org/ALVR/wiki/Troubleshooting")!)
                    Link("Discord", destination: URL(string: "https://discord.gg/ALVR")!)
                    Link("Matrix", destination: URL(string: "https://matrix.to/#/#alvr:ckie.dev?via=ckie.dev")!)
                    Text("开源许可：MIT License")
                    Link("完整许可信息", destination: URL(string: "https://raw.githubusercontent.com/alvr-org/ALVR/master/LICENSE")!)
                    Divider().padding(.vertical, 8)
                    Text("联系我（汉化作者）")
                    Link("哔哩哔哩 @caidingding233", destination: URL(string: "https://space.bilibili.com/351210149")!)
                }
                .frame(minWidth: 450)
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 设置行视图
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
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
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
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

// 状态消息翻译函数
func translateStatusMessage(_ message: String) -> String {
    let lowercased = message.lowercased()
    
    // 根据 Rust 代码中的状态消息进行翻译
    if lowercased.contains("searching for streamer") {
        return "正在搜索串流服务器..."
    } else if lowercased.contains("open alvr on your pc") {
        return "请在电脑上打开ALVR并点击\"信任\""
    } else if lowercased.contains("network error") || lowercased.contains("cannot connect") {
        return "网络连接错误"
    } else if lowercased.contains("successful connection") {
        return "连接成功！请稍候..."
    } else if lowercased.contains("trying to connect to localhost") {
        return "正在尝试连接本地服务器..."
    } else if lowercased.contains("stream will begin soon") {
        return "串流即将开始，请稍候..."
    } else if lowercased.contains("streamer is restarting") {
        return "串流服务器正在重启，请稍候..."
    } else if lowercased.contains("streamer has disconnected") {
        return "串流服务器已断开连接"
    } else if lowercased.contains("connection timeout") {
        return "连接超时"
    } else if lowercased.contains("connection error") {
        return "连接错误，请检查电脑端详情"
    } else {
        // 如果没有匹配的翻译，返回原始消息
        return message
    }
}

// 设置视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gStore: GlobalSettingsStore
    let refreshRatesPost20 = ["90", "96", "100"]
    let refreshRatesPre20 = ["90", "96"]
    let saveAction: ()->Void
    
    init(saveAction: @escaping ()->Void) {
        self.saveAction = saveAction
    }

    func applyStreamHz() {
        VideoHandler.applyRefreshRate(videoFormat: EventHandler.shared.videoFormat)
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Main Settings:")
                    .font(.system(size: 20, weight: .bold))
                Toggle(isOn: $gStore.settings.showHandsOverlaid) {
                    Text("Show hands overlaid")
                }
                .toggleStyle(.switch)
                
                Toggle(isOn: $gStore.settings.disablePersistentSystemOverlays) {
                    Text("Disable persistent system overlays (palm gesture)")
                }
                .toggleStyle(.switch)
                
                Toggle(isOn: $gStore.settings.keepSteamVRCenter) {
                    Text("Crown Button long-press ignored by SteamVR")
                }
                .toggleStyle(.switch)
                        
                        Toggle(isOn: $gStore.settings.emulatedPinchInteractions) {
                    Text("Emulate pinch interactions as controller inputs")
                        }
                .toggleStyle(.switch)
                        
                        HStack {
                    Text("Stream refresh rate*")
                    Picker("Stream refresh rate", selection: $gStore.settings.streamFPS) {
                                if #unavailable(visionOS 2.0) {
                                    ForEach(refreshRatesPre20, id: \.self) {
                                        Text($0)
                                    }
                                }
                                else {
                                    ForEach(refreshRatesPost20, id: \.self) {
                                        Text($0)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: gStore.settings.streamFPS) {
                                applyStreamHz()
                            }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if #unavailable(visionOS 2.0) {
                    Text("*Higher refresh rates cause skipping when displaying 30P content, or judder while passthrough is active")
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                else {
                    Text("*Higher refresh rates cause skipping when displaying 30P content")
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minWidth: 450)
            .padding()
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    dismiss()
                }
            )
        }
    }
}

// 高级设置视图（CSA/渲染/抠像等）
struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gStore: GlobalSettingsStore
    @Binding var chromaKeyColor: Color
    @State private var chromaRangeMaximum: Float = 1.0
    let saveAction: ()->Void
    let chromaFormatter: NumberFormatter
    var onClose: (() -> Void)? = nil

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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Advanced Settings:")
                        .font(.system(size: 20, weight: .bold))

                    Toggle(isOn: $gStore.settings.experimental40ppd) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Experimental 40PPD renderer*")
                            Text("*Experimental! May cause juddering and/or nausea!")
                                .font(.system(size: 10))
                        }
                    }
                    .toggleStyle(.switch)

                    Toggle(isOn: $gStore.settings.chromaKeyEnabled) {
#if XCODE_BETA_16
                        if #unavailable(visionOS 2.0) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Chroma Keyed Passthrough*")
                                Text("*Only works with 40PPD renderer")
                                    .font(.system(size: 10))
                            }
                        }
                        else {
                            Text("Enable Chroma Keyed Passthrough")
                        }
#else
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Chroma Keyed Passthrough*")
                            Text("*Only works with 40PPD renderer")
                                .font(.system(size: 10))
                        }
#endif
                    }
                    .toggleStyle(.switch)
                        .onChange(of: gStore.settings.chromaKeyEnabled) {
                            saveAction()
                        }
                        
                    ColorPicker("Chroma Key Color", selection: $chromaKeyColor)
                                .onChange(of: chromaKeyColor) {
                                    gStore.settings.chromaKeyColorR = Float((chromaKeyColor.cgColor?.components ?? [0.0, 1.0, 0.0])[0])
                                    gStore.settings.chromaKeyColorG = Float((chromaKeyColor.cgColor?.components ?? [0.0, 1.0, 0.0])[1])
                                    gStore.settings.chromaKeyColorB = Float((chromaKeyColor.cgColor?.components ?? [0.0, 1.0, 0.0])[2])
                                    saveAction()
                                }
                            
                    Text("Chroma Blend Distance Min/Max").frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Slider(value: $gStore.settings.chromaKeyDistRangeMin,
                                           in: 0...chromaRangeMaximum,
                               step: 0.01) {
                            Text("Chroma Blend Distance Min")
                        }
                                    .onChange(of: gStore.settings.chromaKeyDistRangeMin) {
                                        applyRangeSettings()
                                    }
                        TextField("Chroma Blend Distance Min", value: $gStore.settings.chromaKeyDistRangeMin, formatter: chromaFormatter)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: gStore.settings.chromaKeyDistRangeMin) {
                                applyRangeSettings()
                            }
                            .frame(width: 100)
                                }
                                HStack {
                                    Slider(value: $gStore.settings.chromaKeyDistRangeMax,
                                           in: 0.001...1,
                               step: 0.01) {
                            Text("Chroma Blend Distance Max")
                        }
                                    .onChange(of: gStore.settings.chromaKeyDistRangeMax) {
                                        applyRangeSettings()
                                    }
                        TextField("Chroma Blend Distance Max", value: $gStore.settings.chromaKeyDistRangeMax, formatter: chromaFormatter)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: gStore.settings.chromaKeyDistRangeMax) {
                                applyRangeSettings()
                            }
                            .frame(width: 100)
                    }

#if XCODE_BETA_16
                    Toggle(isOn: $gStore.settings.forceMipmapEyeTracking) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Force visionOS 1.x eye tracking")
                            Text("*Eye tracking requires Experimental Renderer. Moves faster, but requires obstructing the left eye FoV.")
                                .font(.system(size: 10))
                            Text("Long click View Recording in the Control Center to select ALVR broadcaster.")
                                .font(.system(size: 10))
                        }
                    }
                    .toggleStyle(.switch)
#endif
                        
                        Toggle(isOn: $gStore.settings.dismissWindowOnEnter) {
                        Text("Dismiss this window on entry")
                        }
                    .toggleStyle(.switch)
                        
                    Text("FoV Scale").frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Slider(value: $gStore.settings.fovRenderScale,
                                       in: 0.2...1.6,
                               step: 0.1) {
                            Text("FoV Scale")
                        }
                                .onChange(of: gStore.settings.fovRenderScale) {
                                    applyRangeSettings()
                                }
                        TextField("FoV Scale", value: $gStore.settings.fovRenderScale, formatter: chromaFormatter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: gStore.settings.fovRenderScale) {
                                applyRangeSettings()
                            }
                            .frame(width: 100)
                    }
                    Text("Increase FoV for timewarp comfort, or sacrifice FoV for sharpness")
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 450)
                .padding()
            }
            .navigationTitle("高级设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        onClose?()
                        dismiss()
                    }
                }
            }
        }
    }
}
