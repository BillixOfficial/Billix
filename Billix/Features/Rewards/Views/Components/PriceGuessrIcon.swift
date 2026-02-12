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

    var body: some View {
        ZStack {
            // Glow rings
            ForEach(0..<2) { index in
                Circle()
                    .stroke(Color.billixMoneyGreen.opacity(0.25), lineWidth: 2)
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
            Animated3DDollarSign(offsetX: 0.25, offsetY: -0.10, scale: 1.40)
                .frame(width: 168, height: 168)
                .offset(y: isAnimating ? -4 : 4)
        }
        .frame(width: 178, height: 178)
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

        // Sage green metallic material (~#6B8F71)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.42, green: 0.56, blue: 0.44, alpha: 1.0)
        material.specular.contents = UIColor.white
        material.shininess = 0.8
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.80
        material.roughness.contents = 0.22

        // Edge material (darker sage for depth)
        let edgeMaterial = SCNMaterial()
        edgeMaterial.diffuse.contents = UIColor(red: 0.30, green: 0.44, blue: 0.32, alpha: 1.0)
        edgeMaterial.specular.contents = UIColor.white
        edgeMaterial.shininess = 0.7
        edgeMaterial.lightingModel = .physicallyBased
        edgeMaterial.metalness.contents = 0.85
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

        // Key light (front-right, neutral-cool for green highlight)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light!.type = .directional
        keyLight.light!.color = UIColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 1.0)
        keyLight.light!.intensity = 1300
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
            // Tag background - unified accent color
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F0A830"), Color(hex: "#E89520")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 45, height: 28)
                .shadow(color: Color(hex: "#F0A830").opacity(0.5), radius: 6, x: 0, y: 3)

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

struct PriceGuessrIcon_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#2d5a5e")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                PriceGuessrIcon()

                Text("Animated Dollar Sign with Price Tag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .previewDisplayName("Price Guessr Icon")
    }
}
