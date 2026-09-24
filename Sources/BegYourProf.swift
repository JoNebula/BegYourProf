import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum AuraStyle {
    static let gold = Color(red: 0.94, green: 0.72, blue: 0.28)
    static let darkGold = Color(red: 0.50, green: 0.31, blue: 0.06)
    static let ink = Color(red: 0.22, green: 0.17, blue: 0.13)
}

@MainActor
private enum PortraitStore {
    static let fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("BegYourProf", isDirectory: true)
        .appendingPathComponent("portrait")

    static func load() -> NSImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return NSImage(data: data)
    }

    static func importImage(from sourceURL: URL) throws -> NSImage {
        let data = try Data(contentsOf: sourceURL)
        guard let image = NSImage(data: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        return image
    }

    static func removeCustomImage() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    static func bundledAvatar() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "default-avatar", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
}

@MainActor
final class AuraModel: ObservableObject {
    @Published var portrait: NSImage?
    @Published var usingCustomPortrait = false
    @Published var worshipCount = UserDefaults.standard.integer(forKey: "worshipCount")
    @Published var messageIndex = 0
    @Published var showBlessing = false

    let messages = [
        "오늘도 논문에 빛이 있으라",
        "수정 코멘트는 곧 계시입니다",
        "연구의 길을 밝혀주소서",
        "마감 앞에도 평온을 주소서",
        "리비전이 은총으로 바뀌기를"
    ]

    init() {
        let customPortrait = PortraitStore.load()
        portrait = customPortrait ?? PortraitStore.bundledAvatar()
        usingCustomPortrait = customPortrait != nil
    }

    func worship() {
        worshipCount += 1
        UserDefaults.standard.set(worshipCount, forKey: "worshipCount")
        messageIndex = (messageIndex + 1) % messages.count
        showBlessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.showBlessing = false
        }
    }
}

struct AuraRay: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

struct AuraRays: View {
    @State private var rotating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AuraStyle.gold.opacity(0.48))
                .frame(width: 242, height: 242)
                .blur(radius: 30)
            ForEach(0..<48, id: \.self) { index in
                AuraRay()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0.90, blue: 0.34).opacity(0.03),
                                Color(red: 1, green: 0.91, blue: 0.40).opacity(index.isMultiple(of: 3) ? 0.64 : 0.36)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: index.isMultiple(of: 3) ? 13 : 8, height: index.isMultiple(of: 3) ? 102 : 78)
                    .offset(y: index.isMultiple(of: 3) ? -103 : -94)
                    .rotationEffect(.degrees(Double(index) * 7.5))
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.94), Color(red: 1, green: 0.98, blue: 0.64).opacity(0.92), AuraStyle.gold.opacity(0)],
                        center: .center,
                        startRadius: 14,
                        endRadius: 124
                    )
                )
                .frame(width: 248, height: 248)
                .blur(radius: 7)
            Circle()
                .stroke(Color(red: 1, green: 0.93, blue: 0.48).opacity(0.8), lineWidth: 3)
                .frame(width: 192, height: 192)
                .blur(radius: 4)
        }
        .frame(width: 270, height: 250)
        .rotationEffect(.degrees(rotating ? 360 : 0))
        .onAppear {
            withAnimation(.linear(duration: 48).repeatForever(autoreverses: false)) {
                rotating = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct AuraCard: View {
    @ObservedObject var model: AuraModel
    let hide: () -> Void
    let choosePhoto: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "sparkle")
                Text("연구실 수호신")
                    .tracking(2.5)
                Image(systemName: "sparkle")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(AuraStyle.darkGold)
            .padding(.top, 18)

            Text(model.portrait == nil ? "BegYourProf" : "지도교수님 강림")
                .font(.system(size: 21, weight: .heavy, design: .serif))
                .foregroundStyle(AuraStyle.ink)
                .padding(.top, 5)

            ZStack {
                AuraRays()
                Button(action: choosePhoto) {
                    Group {
                        if let portrait = model.portrait {
                            Image(nsImage: portrait)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 9) {
                                Image(systemName: "person.crop.rectangle")
                                    .font(.system(size: 37, weight: .ultraLight))
                                Text("사진을 선택하세요")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(AuraStyle.darkGold.opacity(0.75))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white.opacity(0.82))
                        }
                    }
                    .frame(width: 132, height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.95), lineWidth: 4)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AuraStyle.gold, lineWidth: 1.5)
                            .padding(3)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AuraStyle.darkGold)
                            .frame(width: 21, height: 21)
                            .background(.white, in: Circle())
                            .padding(6)
                    }
                    .shadow(color: AuraStyle.darkGold.opacity(0.25), radius: 12, y: 7)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("사진 바꾸기")
                Text("✦")
                    .font(.system(size: 22))
                    .foregroundStyle(AuraStyle.gold)
                    .offset(x: -89, y: -81)
                Text("✦")
                    .font(.system(size: 16))
                    .foregroundStyle(AuraStyle.gold)
                    .offset(x: 91, y: 60)
            }
            .frame(height: 208)

            Text(model.portrait == nil ? "사진을 넣어 후광을 켜세요" : model.messages[model.messageIndex])
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AuraStyle.ink)
                .lineLimit(1)
                .contentTransition(.opacity)
                .padding(.top, 1)

            Button(action: {
                if model.portrait == nil { choosePhoto() } else { model.worship() }
            }) {
                HStack(spacing: 7) {
                    if model.portrait == nil {
                        Image(systemName: "photo.badge.plus")
                        Text("사진 선택하기")
                    } else {
                        Text("🙏")
                        Text("경배하기")
                        Text("·")
                        Text("\(model.worshipCount)회")
                            .monospacedDigit()
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.65, green: 0.40, blue: 0.12), Color(red: 0.42, green: 0.25, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 25)
            .padding(.top, 14)

            HStack(spacing: 4) {
                Image(systemName: "hand.draw")
                Text("빈 곳: 이동 · 테두리: 크기 조절")
            }
            .font(.system(size: 9))
            .foregroundStyle(AuraStyle.ink.opacity(0.55))
            .padding(.top, 8)
            .padding(.bottom, 13)
        }
        .frame(width: 270, height: 365)
        .background {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.88), AuraStyle.gold.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .stroke(AuraStyle.gold.opacity(0.85), lineWidth: 1.5)
                }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: hide) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AuraStyle.darkGold.opacity(0.65))
                    .frame(width: 22, height: 22)
                    .background(.white.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("후광 숨기기")
            .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            if model.showBlessing {
                Text("✨ 은총 +1")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AuraStyle.darkGold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.white, in: Capsule())
                    .padding(.top, 71)
                    .padding(.trailing, 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AuraStyle.darkGold.opacity(0.55))
                .padding(11)
                .accessibilityHidden(true)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.showBlessing)
    }
}

struct ResizableAuraView: View {
    @ObservedObject var model: AuraModel
    let hide: () -> Void
    let choosePhoto: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 270, geometry.size.height / 365)
            AuraCard(model: model, hide: hide, choosePhoto: choosePhoto)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = AuraModel()
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var toggleItem: NSMenuItem!
    private var worshipItem: NSMenuItem!
    private var resetPhotoItem: NSMenuItem!
    private var isOverlayVisible = UserDefaults.standard.object(forKey: "overlayVisible") as? Bool ?? true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let card = ResizableAuraView(
            model: model,
            hide: { [weak self] in self?.toggleOverlay() },
            choosePhoto: { [weak self] in self?.choosePortrait() }
        )
        let savedWidth = UserDefaults.standard.double(forKey: "overlayWidth")
        let initialWidth = savedWidth > 0 ? min(max(savedWidth, 200), 540) : 270
        let initialHeight = initialWidth * 365 / 270
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: card)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.contentMinSize = NSSize(width: 200, height: 200 * 365 / 270)
        panel.contentMaxSize = NSSize(width: 540, height: 730)
        panel.contentAspectRatio = NSSize(width: 270, height: 365)
        panel.delegate = self

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.maxX - initialWidth - 28, y: frame.maxY - initialHeight - 32))
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ BegYourProf"
            button.toolTip = "BegYourProf"
        }

        let menu = NSMenu()
        let heading = NSMenuItem(title: "✦ BegYourProf", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: "후광 보이기", action: #selector(toggleOverlay), keyEquivalent: "o")
        toggleItem.target = self
        toggleItem.state = isOverlayVisible ? .on : .off
        menu.addItem(toggleItem)

        let photoItem = NSMenuItem(title: "사진 넣기 / 바꾸기…", action: #selector(choosePortrait), keyEquivalent: "p")
        photoItem.target = self
        menu.addItem(photoItem)

        resetPhotoItem = NSMenuItem(title: "기본 아바타로 돌아가기", action: #selector(resetPortrait), keyEquivalent: "")
        resetPhotoItem.target = self
        resetPhotoItem.isEnabled = model.usingCustomPortrait
        menu.addItem(resetPhotoItem)
        menu.addItem(.separator())

        worshipItem = NSMenuItem(title: "🙏 한 번 더 경배하기", action: #selector(worshipFromMenu), keyEquivalent: "w")
        worshipItem.target = self
        worshipItem.isEnabled = model.portrait != nil
        menu.addItem(worshipItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        if isOverlayVisible { panel.orderFrontRegardless() }
    }

    func windowDidResize(_ notification: Notification) {
        UserDefaults.standard.set(panel.contentRect(forFrameRect: panel.frame).width, forKey: "overlayWidth")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !isOverlayVisible {
            toggleOverlay()
        } else {
            panel.orderFrontRegardless()
        }
        return true
    }

    @objc private func toggleOverlay() {
        isOverlayVisible.toggle()
        UserDefaults.standard.set(isOverlayVisible, forKey: "overlayVisible")
        toggleItem.state = isOverlayVisible ? .on : .off
        if isOverlayVisible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    @objc private func worshipFromMenu() {
        if !isOverlayVisible { toggleOverlay() }
        model.worship()
    }

    @objc private func choosePortrait() {
        let picker = NSOpenPanel()
        picker.title = "사진 선택"
        picker.message = "선택한 사진은 이 Mac의 Application Support에만 저장됩니다."
        picker.prompt = "사용"
        picker.allowedContentTypes = [.image]
        picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false
        NSApp.activate(ignoringOtherApps: true)
        guard picker.runModal() == .OK, let url = picker.url else { return }

        do {
            model.portrait = try PortraitStore.importImage(from: url)
            model.usingCustomPortrait = true
            resetPhotoItem.isEnabled = true
            worshipItem.isEnabled = true
            if !isOverlayVisible { toggleOverlay() }
            panel.orderFrontRegardless()
        } catch {
            let alert = NSAlert()
            alert.messageText = "사진을 열 수 없습니다"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    @objc private func resetPortrait() {
        do {
            try PortraitStore.removeCustomImage()
            model.portrait = PortraitStore.bundledAvatar()
            model.usingCustomPortrait = false
            resetPhotoItem.isEnabled = false
            worshipItem.isEnabled = model.portrait != nil
        } catch {
            let alert = NSAlert()
            alert.messageText = "기본 아바타로 돌아갈 수 없습니다"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

@main
struct BegYourProfApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
