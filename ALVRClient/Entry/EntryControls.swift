/*
Abstract:
Controls that allow entry into the ALVR environment.
*/

import SwiftUI

/// Controls that allow entry into the ALVR environment.
struct EntryControls: View {
    @Environment(ViewModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    let saveAction: ()->Void

    var body: some View {
        @Bindable var model = model
        
        VStack(spacing: 20) {
            // 主控制按钮 - 使用visionOS风格
            Button(action: {
                if eventHandler.connectionState == .connected {
                    model.isShowingClient.toggle()
                }
            }) {
                VStack(spacing: 12) {
                    Image(systemName: getButtonIcon())
                        .font(.system(size: 50))
                        .fontWeight(.medium)
                    
                    Text(getButtonText())
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .frame(width: 200, height: 200)
                .foregroundColor(getButtonColor())
            }
            .buttonStyle(.bordered)
            .controlSize(.extraLarge)
            .disabled(eventHandler.connectionState != .connected)
            .opacity(eventHandler.connectionState == .connected ? 1.0 : 0.6)
            
            // 状态指示器
            if eventHandler.connectionState != .connected {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("等待连接...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        //Enable Client
        .onChange(of: model.isShowingClient) { _, isShowing in
            Task {
                if isShowing {
                    saveAction()
                    print("Opening Immersive Space")
                    if gStore.settings.experimental40ppd {
                        if !DummyMetalRenderer.haveRenderInfo {
                            var dummySpaceIsOpened = false
                            while !dummySpaceIsOpened {
                                switch await openImmersiveSpace(id: "DummyImmersiveSpace") {
                                case .opened:
                                    dummySpaceIsOpened = true
                                case .error, .userCancelled:
                                    fallthrough
                                @unknown default:
                                    dummySpaceIsOpened = false
                                }
                            }
                            
                            while dummySpaceIsOpened && !DummyMetalRenderer.haveRenderInfo {
                                try! await Task.sleep(nanoseconds: 1_000_000)
                            }
                            
                            await dismissImmersiveSpace()
                            try! await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                        
                        if !DummyMetalRenderer.haveRenderInfo {
                            print("MISSING VIEW INFO!!")
                        }
                        
                        WorldTracker.shared.worldTrackingAddedOriginAnchor = false
                        
                        print("Open real immersive space")
                        
                        switch await openImmersiveSpace(id: "RealityKitClient") {
                        case .opened:
                            immersiveSpaceIsShown = true
                        case .error, .userCancelled:
                            fallthrough
                        @unknown default:
                            immersiveSpaceIsShown = false
                            showImmersiveSpace = false
                        }
                    }
                    else {
                        await openImmersiveSpace(id: "MetalClient")
                    }
                    VideoHandler.applyRefreshRate(videoFormat: EventHandler.shared.videoFormat)
                    if gStore.settings.dismissWindowOnEnter {
                        dismissWindow(id: "Entry")
                    }
                }
            }
        }
    }
    
    private func getButtonIcon() -> String {
        if eventHandler.connectionState != .connected {
            return "wifi.slash"
        } else if model.isShowingClient {
            return "stop.fill"
        } else {
            return "play.fill"
        }
    }
    
    private func getButtonText() -> String {
        if eventHandler.connectionState != .connected {
            return "未连接"
        } else if model.isShowingClient {
            return "停止串流"
        } else {
            return "开始串流"
        }
    }
    
    private func getButtonColor() -> Color {
        if eventHandler.connectionState != .connected {
            return .gray
        } else if model.isShowingClient {
            return .red
        } else {
            return .blue
        }
    }
}