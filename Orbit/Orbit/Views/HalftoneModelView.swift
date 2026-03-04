import SwiftUI
import SceneKit
import UniformTypeIdentifiers

/// Loads a 3D model, renders it with SceneKit, and converts the output
/// to the halftone dot-matrix pixel art style from the reference images.
/// Supports interactive rotation — the pixel art updates in real time.
struct HalftoneModelView: View {
    @StateObject private var renderer = HalftoneRenderer()
    @State private var showFilePicker = false

    var compact: Bool = false
    var gridResolution: Int = 48
    var dotColor: Color = OrbitTheme.accent

    var body: some View {
        ZStack {
            if renderer.hasModel {
                // Halftone canvas
                HalftoneCanvas(
                    brightness: renderer.brightnessGrid,
                    gridSize: renderer.resolution,
                    dotColor: dotColor
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            renderer.rotate(dx: value.translation.width, dy: value.translation.height)
                        }
                        .onEnded { _ in
                            renderer.commitRotation()
                        }
                )
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            renderer.zoom(scale: value.magnification)
                        }
                )
                .overlay(alignment: .bottomTrailing) {
                    if !compact {
                        Button {
                            renderer.clearModel()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
            } else {
                // Drop zone
                VStack(spacing: 10) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: compact ? 24 : 36))
                        .foregroundStyle(OrbitTheme.accent.opacity(0.5))
                    if !compact {
                        Text("Drop a 3D model here")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(".obj  .usdz  .scn  .dae")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(OrbitTheme.accent.opacity(0.04), in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: OrbitTheme.cardRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(OrbitTheme.accent.opacity(0.2))
                )
                .onTapGesture {
                    showFilePicker = true
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: modelTypes) { result in
            if case .success(let url) = result {
                renderer.loadModel(from: url, resolution: gridResolution)
            }
        }
        .onAppear {
            renderer.resolution = gridResolution
        }
    }

    private var modelTypes: [UTType] {
        [.usdz, .sceneKitScene, UTType("public.geometry-definition-format") ?? .data, .data]
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
            if let data = data as? Data, let urlStr = String(data: data, encoding: .utf8),
               let url = URL(string: urlStr) {
                DispatchQueue.main.async {
                    renderer.loadModel(from: url, resolution: gridResolution)
                }
            }
        }
        return true
    }
}

// MARK: - Halftone Canvas

struct HalftoneCanvas: View {
    let brightness: [[CGFloat]]
    let gridSize: Int
    let dotColor: Color

    var body: some View {
        Canvas { context, size in
            let cols = brightness.first?.count ?? 0
            let rows = brightness.count
            guard cols > 0, rows > 0 else { return }

            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)
            let cellSize = min(cellW, cellH)
            let dotSize = cellSize * 0.82
            let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
            let offsetY = (size.height - CGFloat(rows) * cellSize) / 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let b = brightness[row][col]
                    guard b > 0.02 else { continue }

                    let x = offsetX + CGFloat(col) * cellSize + (cellSize - dotSize) / 2
                    let y = offsetY + CGFloat(row) * cellSize + (cellSize - dotSize) / 2
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)

                    context.fill(
                        RoundedRectangle(cornerRadius: dotSize * 0.2).path(in: rect),
                        with: .color(dotColor.opacity(Double(b)))
                    )
                }
            }
        }
    }
}

// MARK: - Renderer

class HalftoneRenderer: ObservableObject {
    @Published var brightnessGrid: [[CGFloat]] = []
    @Published var hasModel = false
    var resolution: Int = 48

    private var scene: SCNScene?
    private var scnRenderer: SCNRenderer?
    private var cameraNode: SCNNode?
    private var displayLink: CVDisplayLink?

    // Rotation state
    private var currentYaw: CGFloat = 0
    private var currentPitch: CGFloat = 0
    private var dragStartYaw: CGFloat = 0
    private var dragStartPitch: CGFloat = 0
    private var currentZoom: CGFloat = 1.0

    func loadModel(from url: URL, resolution: Int) {
        self.resolution = resolution

        // Access security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let scene = try? SCNScene(url: url, options: [
            .checkConsistency: true
        ]) else {
            // Try loading as generic
            guard let scene = try? SCNScene(url: url) else { return }
            self.scene = scene
            setupRenderer()
            return
        }

        self.scene = scene
        setupRenderer()
    }

    private func setupRenderer() {
        guard let scene = scene else { return }

        // Create renderer
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        renderer.autoenablesDefaultLighting = true

        // Setup camera
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)

        // Position camera to frame the model
        let (minVec, maxVec) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        let extent = SCNVector3(
            maxVec.x - minVec.x,
            maxVec.y - minVec.y,
            maxVec.z - minVec.z
        )
        let maxExtent = max(extent.x, max(extent.y, extent.z))

        // Set neutral material color if model has none
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                for material in geometry.materials {
                    if material.diffuse.contents == nil {
                        material.diffuse.contents = NSColor.white
                    }
                }
            }
        }

        // Add ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        let dist = CGFloat(maxExtent) * 2.0
        cameraNode.position = SCNVector3(center.x, center.y, center.z + dist)
        cameraNode.look(at: center)

        self.cameraNode = cameraNode
        self.scnRenderer = renderer
        self.currentZoom = CGFloat(maxExtent) * 2.0

        DispatchQueue.main.async {
            self.hasModel = true
        }

        renderFrame()
        startAutoRotate()
    }

    private func startAutoRotate() {
        // Gentle auto-rotation
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.hasModel else { return }
            self.currentYaw += 0.005
            self.renderFrame()
        }
    }

    func rotate(dx: CGFloat, dy: CGFloat) {
        let sensitivity: CGFloat = 0.008
        currentYaw = dragStartYaw + dx * sensitivity
        currentPitch = max(-.pi / 2.5, min(.pi / 2.5, dragStartPitch - dy * sensitivity))
        renderFrame()
    }

    func commitRotation() {
        dragStartYaw = currentYaw
        dragStartPitch = currentPitch
    }

    func zoom(scale: CGFloat) {
        currentZoom = max(0.5, currentZoom / scale)
        renderFrame()
    }

    func clearModel() {
        scene = nil
        scnRenderer = nil
        cameraNode = nil
        DispatchQueue.main.async {
            self.hasModel = false
            self.brightnessGrid = []
        }
    }

    func renderFrame() {
        guard let renderer = scnRenderer, let camera = cameraNode, let scene = scene else { return }

        // Update camera orbit
        let (minVec, maxVec) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )

        let cx = CGFloat(center.x)
        let cy = CGFloat(center.y)
        let cz = CGFloat(center.z)
        let x = currentZoom * sin(currentYaw) * cos(currentPitch) + cx
        let y = currentZoom * sin(currentPitch) + cy
        let z = currentZoom * cos(currentYaw) * cos(currentPitch) + cz
        camera.position = SCNVector3(x, y, z)
        camera.look(at: center)

        renderer.pointOfView = camera

        // Render to image
        let renderSize = CGSize(width: CGFloat(resolution) * 4, height: CGFloat(resolution) * 4)
        let image = renderer.snapshot(atTime: 0, with: renderSize, antialiasingMode: .multisampling4X)

        // Convert to brightness grid
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample into grid
        let cellW = width / resolution
        let cellH = height / resolution
        var grid = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: resolution), count: resolution)

        for row in 0..<resolution {
            for col in 0..<resolution {
                var totalBrightness: CGFloat = 0
                var sampleCount = 0
                let startX = col * cellW
                let startY = row * cellH

                for dy in stride(from: 0, to: cellH, by: max(1, cellH / 4)) {
                    for dx in stride(from: 0, to: cellW, by: max(1, cellW / 4)) {
                        let px = startX + dx
                        let py = startY + dy
                        guard px < width, py < height else { continue }

                        let offset = (py * bytesPerRow) + (px * bytesPerPixel)
                        let r = CGFloat(pixelData[offset]) / 255.0
                        let g = CGFloat(pixelData[offset + 1]) / 255.0
                        let b = CGFloat(pixelData[offset + 2]) / 255.0
                        let a = CGFloat(pixelData[offset + 3]) / 255.0

                        // Luminance with alpha
                        let lum = (0.299 * r + 0.587 * g + 0.114 * b) * a
                        totalBrightness += lum
                        sampleCount += 1
                    }
                }

                grid[row][col] = sampleCount > 0 ? totalBrightness / CGFloat(sampleCount) : 0
            }
        }

        DispatchQueue.main.async {
            self.brightnessGrid = grid
        }
    }
}
