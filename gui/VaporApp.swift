import SwiftUI
import AppKit

@main
struct VaporApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 720, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

class VaporRunner: ObservableObject {
    @Published var isEngineInstalled: Bool = false
    @Published var isSteamInstalled: Bool = false
    @Published var isCS2Installed: Bool = false
    @Published var isHUDEnabled: Bool = false
    @Published var isRunningTask: Bool = false
    @Published var statusLog: String = "Ready.\n"

    let rootDir: URL
    let engineDir: URL
    let defaultBottleDir: URL
    let steamExe: URL
    let cs2Exe: URL
    let configFile: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let vaporPath = home.appendingPathComponent(".gemini/antigravity/scratch/vapor")
        self.rootDir = vaporPath
        self.engineDir = vaporPath.appendingPathComponent("engines/default")
        self.defaultBottleDir = vaporPath.appendingPathComponent("bottles/Steam")
        self.steamExe = defaultBottleDir.appendingPathComponent("drive_c/Program Files (x86)/Steam/steam.exe")
        self.cs2Exe = defaultBottleDir.appendingPathComponent("drive_c/Program Files (x86)/Steam/steamapps/common/Counter-Strike Global Offensive/game/bin/win64/cs2.exe")
        self.configFile = vaporPath.appendingPathComponent("config.env")

        refreshStatus()
    }

    func refreshStatus() {
        let wineloader = engineDir.appendingPathComponent("bin/wineloader").path
        let wine64 = engineDir.appendingPathComponent("bin/wine64").path
        let wine = engineDir.appendingPathComponent("bin/wine").path
        self.isEngineInstalled = FileManager.default.fileExists(atPath: wineloader) ||
                                 FileManager.default.fileExists(atPath: wine64) ||
                                 FileManager.default.fileExists(atPath: wine)

        self.isSteamInstalled = FileManager.default.fileExists(atPath: steamExe.path)
        self.isCS2Installed = FileManager.default.fileExists(atPath: cs2Exe.path)

        if let content = try? String(contentsOf: configFile, encoding: .utf8) {
            self.isHUDEnabled = content.contains("HUD_ENABLED=1")
        }
    }

    func appendLog(_ text: String) {
        DispatchQueue.main.async {
            self.statusLog += text + "\n"
        }
    }

    func toggleHUD() {
        isHUDEnabled.toggle()
        let val = isHUDEnabled ? "1" : "0"
        let line = "HUD_ENABLED=\(val)\n"
        try? line.write(to: configFile, atomically: true, encoding: .utf8)
        appendLog(isHUDEnabled ? "✓ Metal HUD Enabled." : "✓ Metal HUD Disabled.")
    }

    func executeCommand(args: [String], completion: (() -> Void)? = nil) {
        isRunningTask = true
        let script = rootDir.appendingPathComponent("bin/vapor").path

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [script] + args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                    self.appendLog(str.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                self.appendLog("[Error] Failed to execute: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                self.isRunningTask = false
                self.refreshStatus()
                completion?()
            }
        }
    }

    func setupEngine() {
        appendLog("[-] Setting up Wine-CX + D3DMetal Engine...")
        executeCommand(args: ["setup"])
    }

    func installSteam() {
        appendLog("[-] Installing Windows Steam into bottle...")
        executeCommand(args: ["install-steam"])
    }

    func launchSteam() {
        appendLog("[-] Launching Windows Steam...")
        executeCommand(args: ["steam"])
    }

    func launchCS2() {
        appendLog("[-] Launching Counter-Strike 2 (Metal 3 + MSYNC)...")
        executeCommand(args: ["cs2"])
    }

    func runExePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []

        if panel.runModal() == .OK, let url = panel.url {
            appendLog("[-] Running EXE: \(url.path)")
            executeCommand(args: ["run", url.path])
        }
    }

    func openWinecfg() {
        executeCommand(args: ["winecfg"])
    }

    func killWine() {
        executeCommand(args: ["kill"])
    }
}

struct ContentView: View {
    @StateObject private var runner = VaporRunner()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text("🎮")
                            .font(.system(size: 32))
                        Text("Vapor")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("v1.0")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    Text("Zero-limit Windows Steam & DirectX 12 Gaming on Apple Silicon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // HUD Toggle
                HStack(spacing: 8) {
                    Text("Metal HUD (FPS)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Toggle("", isOn: Binding(
                        get: { runner.isHUDEnabled },
                        set: { _ in runner.toggleHUD() }
                    ))
                    .toggleStyle(.switch)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area
            HStack(spacing: 16) {
                // Left Column: Actions & Controls
                VStack(spacing: 14) {
                    // Status Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Status")
                            .font(.headline)

                        HStack {
                            Circle()
                                .fill(runner.isEngineInstalled ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            Text("Engine: " + (runner.isEngineInstalled ? "Wine-CX + D3DMetal 2 Ready" : "Not Downloaded"))
                                .font(.subheadline)
                            Spacer()
                            if !runner.isEngineInstalled {
                                Button("Install Engine") {
                                    runner.setupEngine()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(runner.isRunningTask)
                            }
                        }

                        HStack {
                            Circle()
                                .fill(runner.isSteamInstalled ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            Text("Steam: " + (runner.isSteamInstalled ? "Installed in Bottle" : "Not Installed"))
                                .font(.subheadline)
                            Spacer()
                            if !runner.isSteamInstalled {
                                Button("Install Steam") {
                                    runner.installSteam()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(runner.isRunningTask || !runner.isEngineInstalled)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)

                    // Primary Action: Launch Steam
                    Button(action: {
                        runner.launchSteam()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch Windows Steam")
                                    .font(.headline)
                                Text("Runs with Apple Metal 3 + D3DMetal acceleration")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            runner.isSteamInstalled ?
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!runner.isSteamInstalled || runner.isRunningTask)

                    if runner.isCS2Installed {
                        Button(action: {
                            runner.launchCS2()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "cross.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Play Counter-Strike 2")
                                        .font(.headline)
                                    Text("Direct launch • MSYNC & D3DMetal Active")
                                        .font(.caption)
                                        .opacity(0.85)
                                }
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .disabled(runner.isRunningTask)
                    }

                    // Secondary Actions
                    HStack(spacing: 12) {
                        Button(action: {
                            runner.runExePicker()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.title2)
                                Text("Run Windows .EXE")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, minHeight: 65)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(!runner.isEngineInstalled || runner.isRunningTask)

                        Button(action: {
                            runner.openWinecfg()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                Text("Wine Config")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, minHeight: 65)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(!runner.isEngineInstalled || runner.isRunningTask)

                        Button(action: {
                            runner.killWine()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "xmark.octagon")
                                    .font(.title2)
                                Text("Kill Processes")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, minHeight: 65)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .frame(width: 320)

                // Right Column: Live Terminal Output
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Activity Log")
                            .font(.headline)
                        Spacer()
                        if runner.isRunningTask {
                            ProgressView()
                                .controlSize(.small)
                            Text("Working...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("Clear") {
                            runner.statusLog = "Ready.\n"
                        }
                        .controlSize(.small)
                    }

                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(runner.statusLog)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .id("logBottom")
                        }
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.green.opacity(0.9))
                        .cornerRadius(10)
                        .onChange(of: runner.statusLog) { _ in
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
