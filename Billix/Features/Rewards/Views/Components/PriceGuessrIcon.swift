//
//  PriceGuessrIcon.swift
//  Billix
//
//  Created by Claude Code on 11/29/25.
//  Animated 3D spinning dollar sign icon with price tag for Price Guessr card
//

import SwiftUI
import SceneKit

struct PriceGuessrIcon: View {
    @State private var isAnimating = false
    @State private var tagOffset: CGFloat = 0

    // DEBUG: position & scale tuning
    @State private var dollarX: Float = 0.0
    @State private var dollarY: Float = 0.0
    @State private var dollarScale: Float = 1.0
    @State private var showDebug = false

    var body: some View {
        ZStack {
            // Glow rings
            ForEach(0..<2) { index in
                Circle()
                    .stroke(Color.billixArcadeGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 168 + CGFloat(index * 17), height: 168 + CGFloat(index * 17))
                    .opacity(isAnimating ? 0.0 : 0.5)
                    .scaleEffect(isAnimating ? 1.4 : 1.0)
                    .animation(
                        .easeOut(duration: 1.8)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.4),
                        value: isAnimating
                    )
            }

            // 3D Spinning Dollar Sign
            Animated3DDollarSign(offsetX: dollarX, offsetY: dollarY, scale: dollarScale)
                .frame(width: 168, height: 168)
                .offset(y: isAnimating ? -4 : 4)
        }
        .frame(width: 178, height: 178)
        .onTapGesture(count: 2) { showDebug = true }
        .sheet(isPresented: $showDebug) {
            DollarDebugSheet(dollarX: $dollarX, dollarY: $dollarY, dollarScale: $dollarScale)
                .presentationDetents([.height(180)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                tagOffset = -3
            }
        }
        .onDisappear {
            isAnimating = false
            tagOffset = 0
        }
    }
}

// MARK: - Debug Sheet

private struct DollarDebugSheet: View {
    @Binding var dollarX: Float
    @Binding var dollarY: Float
    @Binding var dollarScale: Float

    var body: some View {
        VStack(spacing: 12) {
            Text("X:\(String(format: "%.2f", dollarX))  Y:\(String(format: "%.2f", dollarY))  S:\(String(format: "%.2f", dollarScale))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))

            HStack(spacing: 12) {
                debugBtn("X-") { dollarX -= 0.05 }
                debugBtn("X+") { dollarX += 0.05 }
                Divider().frame(height: 28)
                debugBtn("Y-") { dollarY -= 0.05 }
                debugBtn("Y+") { dollarY += 0.05 }
                Divider().frame(height: 28)
                debugBtn("S-") { dollarScale = max(0.1, dollarScale - 0.1) }
                debugBtn("S+") { dollarScale += 0.1 }
            }

            Button("Reset") {
                dollarX = 0; dollarY = 0; dollarScale = 1.0
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color.red)
            .cornerRadius(8)
        }
        .padding()
    }

    private func debugBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .frame(width: 38, height: 34)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
        }
    }
}

// MARK: - 3D Spinning Dollar Sign using SceneKit

struct Animated3DDollarSign: UIViewRepresentable {
    var offsetX: Float = 0
    var offsetY: Float = 0
    var scale: Float = 1.0

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createDollarScene()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
        sceneView.clipsToBounds = false

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let dollarNode = uiView.scene?.rootNode.childNode(withName: "dollar", recursively: false) else { return }
        dollarNode.position = SCNVector3(offsetX, offsetY, 0)
        dollarNode.scale = SCNVector3(scale, scale, scale)
    }

    private func createDollarScene() -> SCNScene {
        let scene = SCNScene()

        // Create 3D dollar sign text
        let text = SCNText(string: "$", extrusionDepth: 0.3)
        text.font = UIFont.systemFont(ofSize: 1.0, weight: .heavy)
        text.chamferRadius = 0.05
        text.flatness = 0.1

        // Gold/amber metallic material (billixGoldenAmber #e8b54d)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.91, green: 0.71, blue: 0.30, alpha: 1.0)
        material.specular.contents = UIColor.white
        material.shininess = 0.8
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.85
        material.roughness.contents = 0.2

        // Edge material (slightly darker gold for depth)
        let edgeMaterial = SCNMaterial()
        edgeMaterial.diffuse.contents = UIColor(red: 0.80, green: 0.60, blue: 0.22, alpha: 1.0)
        edgeMaterial.specular.contents = UIColor.white
        edgeMaterial.shininess = 0.7
        edgeMaterial.lightingModel = .physicallyBased
        edgeMaterial.metalness.contents = 0.9
        edgeMaterial.roughness.contents = 0.25

        text.materials = [material, edgeMaterial, edgeMaterial]

        // Create node and center the text geometry
        let dollarNode = SCNNode(geometry: text)
        dollarNode.name = "dollar"
        let (min, max) = dollarNode.boundingBox
        let centerX = (min.x + max.x) / 2
        let centerY = (min.y + max.y) / 2
        let centerZ = (min.z + max.z) / 2
        dollarNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY, centerZ)
        dollarNode.position = SCNVector3(offsetX, offsetY, 0)
        dollarNode.scale = SCNVector3(scale, scale, scale)

        // Add rotation animation (same 12-second spin as the old globe)
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 12
        rotation.repeatCount = .infinity
        dollarNode.addAnimation(rotation, forKey: "rotation")

        scene.rootNode.addChildNode(dollarNode)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2.2)
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light for base illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.35, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Key light (front-right, warm tone for gold highlight)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light!.type = .directional
        keyLight.light!.color = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        keyLight.light!.intensity = 1200
        keyLight.position = SCNVector3(2, 2, 3)
        keyLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(keyLight)

        // Fill light (left side, cooler tone for contrast)
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light!.type = .directional
        fillLight.light!.color = UIColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1.0)
        fillLight.light!.intensity = 600
        fillLight.position = SCNVector3(-2, 1, 2)
        fillLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillLight)

        return scene
    }
}

// MARK: - Price Tag

struct PriceTag: View {
    var body: some View {
        ZStack {
            // Tag background
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.billixArcadeGold, Color(hex: "#FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 45, height: 28)
                .shadow(color: .billixArcadeGold.opacity(0.5), radius: 6, x: 0, y: 3)

            // Tag border
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: 45, height: 28)

            // Question mark
            Text("?")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)

            // Tag hole (top-left corner)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 6, height: 6)
                .offset(x: -16, y: -10)

            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                .frame(width: 6, height: 6)
                .offset(x: -16, y: -10)
        }
    }
}

// MARK: - Preview

#Preview("Price Guessr Icon") {
    ZStack {
        Color(hex: "#7C3AED")
            .ignoresSafeArea()

        VStack(spacing: 40) {
            PriceGuessrIcon()

            Text("Animated Dollar Sign with Price Tag")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
