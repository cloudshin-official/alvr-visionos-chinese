//
//  ALVRClientApp.swift
//
// High-level application stuff, notably includes:
// - Changelogs (incl app version checks)
// - The AWDL alert
// - GlobalSettings save/load hooks
// - Each different space:
//   - DummyImmersiveSpace: Literally just fetches FOV information/view transforms and exits
//   - RealityKitClient: The "40PPD" RealityKit renderer.
//   - MetalClient: Old reliable, the 26PPD Metal renderer.
// - Metal Layer config (ContentStageConfiguration)
//

import SwiftUI
import CompositorServices

struct ContentStageConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = .bgra8Unorm_srgb
    
        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled

#if XCODE_BETA_26
        if #available(visionOS 26.0, *) {
            if foveationEnabled {
                configuration.maxRenderQuality = .init(1.0)
            }
            //configuration.drawableRenderContextRasterSampleCount = 1
        }
#endif
        
        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)
        
        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
        
        configuration.colorFormat = .rgba16Float
    }
}

struct AWDLAlertView: View {
    @Environment(\.dismissWindow) var dismissWindow
    @State private var showAlert = false
    let saveAction: ()->Void

    var body: some View {
        VStack {
            Text("检测到网络不稳定")
            Text("（您应该会看到一个提示框）")
            //Text("\nSignificant stuttering was detected within the last minute.\n\nMake sure your PC is directly connected to your router and that the headset is in the line of sight of the router.\n\nMake sure you have AirDrop and Handoff disabled in Settings > General > AirDrop/Handoff.\n\nAlternatively, ensure your router is set to Channel 149 (NA) or 44 (EU).")
        }
        .frame(minWidth: 650, maxWidth: 650, minHeight: 900, maxHeight: 900)
        .onAppear() {
            showAlert = true
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("检测到网络不稳定"),
                message: Text("过去一分钟内检测到严重卡顿。\n\n请确保您的电脑直接连接到路由器，并且头显在路由器的视线范围内。\n\n请确保在设置 > 通用 > AirDrop/接力中禁用了 AirDrop 和接力功能。\n\n或者，确保您的路由器设置为频道 149（北美）或 44（欧洲）。"),
                primaryButton: .default(
                    Text("确定"),
                    action: {
                        dismissWindow(id: "AWDLAlert")
                    }
                ),
                secondaryButton: .destructive(
                    Text("不再显示"),
                    action: {
                        ALVRClientApp.gStore.settings.dontShowAWDLAlertAgain = true
                        saveAction()
                        dismissWindow(id: "AWDLAlert")
                    }
                )
            )
        }
    }
}

@main
struct ALVRClientApp: App {
    @State private var model = ViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    @State private var clientImmersionStyle: ImmersionStyle = .mixed
    
    static var gStore = GlobalSettingsStore()
    @State private var chromaKeyColor = Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    
    static let shared = ALVRClientApp()
    static var showedChangelog = false
    @State private var showChangelog = false
    
    let testChangelog = false
    let changelogText = """
    请参阅帮助和信息选项卡获取有关为 ALVR 设置电脑和网络的 wiki 链接。\n\
    \n\
    ________________________________\n\
    \n\
    更新内容：\n\
    \n\
    • (仅 Testflight) 在 visionOS 26 开发者测试版上添加了对 PSVR2 控制器的支持。\n\
    • (仅 Testflight) 在 Metal（默认）后端添加了高分辨率渲染支持。\n\
    \n\
    ________________________________\n\
    \n\
    错误修复：\n\
    \n\
    • (仅 Testflight) 如果 HEVC 初始化失败，添加了一个临时修复，修复了发布版本中的 HEVC 支持。\n\
    • (仅 Testflight) 降低了 PSVR2 控制器的触觉反馈强度，以避免跟踪精度损失和一般不适\n\
      （这显然与 PCVR 盒子不准确，后者的强度也非常高）。\n\
    \n\
    ________________________________\n\
    \n\
    已知问题：\n\
    \n\
    • 尽管手部可见性设置为关闭，手部仍可能显示。这是一个长期存在的 visionOS 错误。打开和关闭控制中心可以修复。\n\
    • 在 v20.11.0 之前的流媒体版本上，控制器可能不稳定。请更新您的流媒体服务器以解决此问题。\n\
    • (仅 Testflight) PSVR2 控制器的右系统按钮在 SteamVR 中不起作用。\n\
    • (仅 Testflight) PSVR2 控制器目前缺少按钮触摸支持（可能是 Apple 的错误）。\n\
    
    """
    
    func saveSettings() {
        do {
            try ALVRClientApp.gStore.save(settings: ALVRClientApp.gStore.settings)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func loadSettings() {
        do {
            try ALVRClientApp.gStore.load()
        } catch {
            fatalError(error.localizedDescription)
        }
        chromaKeyColor = Color(.sRGB, red: Double(ALVRClientApp.gStore.settings.chromaKeyColorR), green: Double(ALVRClientApp.gStore.settings.chromaKeyColorG), blue: Double(ALVRClientApp.gStore.settings.chromaKeyColorB))
        
        // Check if the app version has changed and show a changelog if so
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let buildVersionNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                let currentVersion = appVersion + " build " + buildVersionNumber
                print("Previous version:", ALVRClientApp.gStore.settings.lastUsedAppVersion)
                print("Current version:", currentVersion)
                if currentVersion != ALVRClientApp.gStore.settings.lastUsedAppVersion || (testChangelog && !ALVRClientApp.showedChangelog) {
                    ALVRClientApp.gStore.settings.lastUsedAppVersion = currentVersion
                    saveSettings()
                    
                    if !ALVRClientApp.showedChangelog {
                        showChangelog = true
                    }
                    ALVRClientApp.showedChangelog = true
                }
            }
        }
    }

    var body: some Scene {
        //Entry point, this is the default window chosen in Info.plist from UIApplicationPreferredDefaultSceneSessionRole
        WindowGroup(id: "Entry") {
            Entry(chromaKeyColor: $chromaKeyColor) {
                Task {
                    saveSettings()
                }
            }
            .task {
                if #unavailable(visionOS 2.0) {
                    clientImmersionStyle = .full
                }
                loadSettings()
                model.isShowingClient = false
                EventHandler.shared.initializeAlvr()
                await WorldTracker.shared.initializeAr()
                EventHandler.shared.start()
            }
            .environment(model)
            .environmentObject(EventHandler.shared)
            .environmentObject(ALVRClientApp.gStore)
            .alert(isPresented: $showChangelog) {
                Alert(
                    title: Text("ALVR v" + ALVRClientApp.gStore.settings.lastUsedAppVersion),
                    message: Text(changelogText),
                    dismissButton: .default(
                        Text("关闭"),
                        action: {
                            
                        }
                    )
                )
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                // TODO: revisit if we decide to let app run in background (ie, keep it open + reconnect when headset is donned)
                /*if !model.isShowingClient {
                    //Lobby closed manually: disconnect ALVR
                    //EventHandler.shared.stop()
                    if EventHandler.shared.alvrInitialized {
                        alvr_pause()
                    }
                }
                if !EventHandler.shared.streamingActive {
                    EventHandler.shared.handleHeadsetRemoved()
                }*/
                break
            case .inactive:
                // Scene inactive, currently no action for this
                break
            case .active:
                // Scene active, make sure everything is started if it isn't
                // TODO: revisit if we decide to let app run in background (ie, keep it open + reconnect when headset is donned)
                /*if !model.isShowingClient {
                    WorldTracker.shared.resetPlayspace()
                    EventHandler.shared.initializeAlvr()
                    EventHandler.shared.start()
                    EventHandler.shared.handleHeadsetRemovedOrReentry()
                }
                if EventHandler.shared.alvrInitialized {
                    alvr_resume()
                }*/
                EventHandler.shared.handleHeadsetEntered()
                break
            @unknown default:
                break
            }
        }
        
        // Alert if AWDL-like stuttering behavior is detected
        WindowGroup(id: "AWDLAlert") {
            AWDLAlertView() {
                Task {
                    saveSettings()
                }
            }
            .persistentSystemOverlays(.hidden)
            .environmentObject(ALVRClientApp.gStore)
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        
        ImmersiveSpace(id: "DummyImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                let renderer = DummyMetalRenderer(layerRenderer)
                renderer.startRenderLoop()
            }
        }
        .disablePersistentSystemOverlaysForVisionOS2(shouldDisable: ALVRClientApp.gStore.settings.disablePersistentSystemOverlays ? .hidden : .automatic)
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(ALVRClientApp.gStore.settings.showHandsOverlaid ? .visible : .hidden)

        ImmersiveSpace(id: "RealityKitClient") {
            RealityKitClientView()
        }
        .disablePersistentSystemOverlaysForVisionOS2(shouldDisable: ALVRClientApp.gStore.settings.disablePersistentSystemOverlays ? .hidden : .automatic)
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        .upperLimbVisibility(ALVRClientApp.gStore.settings.showHandsOverlaid ? .visible : .hidden)

        ImmersiveSpace(id: "MetalClient") {
            CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                let system = MetalClientSystem(layerRenderer)
                system.startRenderLoop()
            }
        }
        .disablePersistentSystemOverlaysForVisionOS2(shouldDisable: ALVRClientApp.gStore.settings.disablePersistentSystemOverlays ? .hidden : .automatic)
        .immersionStyle(selection: $clientImmersionStyle, in: .mixed, .full)
        .upperLimbVisibility(ALVRClientApp.gStore.settings.showHandsOverlaid ? .visible : .hidden)
    }
}
