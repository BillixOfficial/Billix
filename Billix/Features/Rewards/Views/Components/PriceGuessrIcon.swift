//
//  PriceGuessrIcon.swift
//  Billix
//
//  Created by Claude Code on 11/29/25.
//  Animated 3D rotating globe icon with price tag for Price Guessr card
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

            // 3D Rotating Globe
            Animated3DGlobe()
                .frame(width: 168, height: 168)
                .offset(y: isAnimating ? -4 : 4)
        }
        .frame(width: 178, height: 178)
        .onAppear {
            isAnimating = true
            // Vertical bob
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }

            // Price tag bob (slightly different timing)
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

// MARK: - 3D Rotating Globe using SceneKit

struct Animated3DGlobe: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createGlobeScene()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func createGlobeScene() -> SCNScene {
        let scene = SCNScene()

        // Create sphere (globe)
        let sphere = SCNSphere(radius: 0.5)

        // Create material with Earth texture
        let material = SCNMaterial()

        // Try to load earth texture from assets, fall back to procedurally generated
        if let earthTexture = UIImage(named: "earth_texture") {
            material.diffuse.contents = earthTexture
        } else {
            // Generate Earth-like texture with continents
            material.diffuse.contents = UIImage.generateEarthTexture()
        }

        material.specular.contents = UIColor.white
        material.shininess = 0.5
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.0
        material.roughness.contents = 0.8

        sphere.materials = [material]

        // Create node
        let globeNode = SCNNode(geometry: sphere)

        // Add rotation animation
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 12 // 12 seconds for full rotation
        rotation.repeatCount = .infinity
        globeNode.addAnimation(rotation, forKey: "rotation")

        scene.rootNode.addChildNode(globeNode)

        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2)
        scene.rootNode.addChildNode(cameraNode)

        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light (sun)
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.color = UIColor.white
        lightNode.position = SCNVector3(2, 2, 2)
        lightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(lightNode)

        return scene
    }
}

// MARK: - Helper Extension for Earth Texture

extension UIImage {
    static func generateEarthTexture() -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Ocean blue background
            ctx.setFillColor(UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0).cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))

            // Land/continent color
            let landColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0).cgColor

            // More realistic continent shapes
            ctx.setFillColor(landColor)

            // North America (bulkier at top)
            let northAmerica = UIBezierPath()
            northAmerica.move(to: CGPoint(x: 130, y: 140))
            northAmerica.addCurve(to: CGPoint(x: 200, y: 120),
                                 controlPoint1: CGPoint(x: 150, y: 135),
                                 controlPoint2: CGPoint(x: 180, y: 125))
            northAmerica.addCurve(to: CGPoint(x: 250, y: 150),
                                 controlPoint1: CGPoint(x: 220, y: 118),
                                 controlPoint2: CGPoint(x: 245, y: 130))
            northAmerica.addCurve(to: CGPoint(x: 235, y: 210),
                                 controlPoint1: CGPoint(x: 253, y: 175),
                                 controlPoint2: CGPoint(x: 248, y: 195))
            northAmerica.addCurve(to: CGPoint(x: 200, y: 240),
                                 controlPoint1: CGPoint(x: 228, y: 220),
                                 controlPoint2: CGPoint(x: 215, y: 235))
            northAmerica.addCurve(to: CGPoint(x: 130, y: 140),
                                 controlPoint1: CGPoint(x: 165, y: 225),
                                 controlPoint2: CGPoint(x: 135, y: 180))
            northAmerica.close()
            ctx.addPath(northAmerica.cgPath)
            ctx.fillPath()

            // Central America (narrow connector)
            let centralAmerica = UIBezierPath()
            centralAmerica.move(to: CGPoint(x: 180, y: 240))
            centralAmerica.addCurve(to: CGPoint(x: 195, y: 270),
                                   controlPoint1: CGPoint(x: 185, y: 250),
                                   controlPoint2: CGPoint(x: 192, y: 262))
            centralAmerica.addCurve(to: CGPoint(x: 175, y: 285),
                                   controlPoint1: CGPoint(x: 192, y: 278),
                                   controlPoint2: CGPoint(x: 183, y: 284))
            centralAmerica.addCurve(to: CGPoint(x: 170, y: 250),
                                   controlPoint1: CGPoint(x: 172, y: 275),
                                   controlPoint2: CGPoint(x: 168, y: 262))
            centralAmerica.close()
            ctx.addPath(centralAmerica.cgPath)
            ctx.fillPath()

            // South America (bulkier, distinctive shape)
            let southAmerica = UIBezierPath()
            southAmerica.move(to: CGPoint(x: 185, y: 280))
            southAmerica.addCurve(to: CGPoint(x: 230, y: 310),
                                 controlPoint1: CGPoint(x: 198, y: 285),
                                 controlPoint2: CGPoint(x: 220, y: 295))
            southAmerica.addCurve(to: CGPoint(x: 240, y: 385),
                                 controlPoint1: CGPoint(x: 238, y: 330),
                                 controlPoint2: CGPoint(x: 245, y: 365))
            southAmerica.addCurve(to: CGPoint(x: 200, y: 400),
                                 controlPoint1: CGPoint(x: 235, y: 395),
                                 controlPoint2: CGPoint(x: 218, y: 398))
            southAmerica.addCurve(to: CGPoint(x: 175, y: 380),
                                 controlPoint1: CGPoint(x: 188, y: 398),
                                 controlPoint2: CGPoint(x: 180, y: 390))
            southAmerica.addCurve(to: CGPoint(x: 165, y: 295),
                                 controlPoint1: CGPoint(x: 168, y: 355),
                                 controlPoint2: CGPoint(x: 162, y: 320))
            southAmerica.close()
            ctx.addPath(southAmerica.cgPath)
            ctx.fillPath()

            // Africa (distinctive bulge and horn)
            let africa = UIBezierPath()
            africa.move(to: CGPoint(x: 480, y: 200))
            // Western bulge
            africa.addCurve(to: CGPoint(x: 460, y: 260),
                           controlPoint1: CGPoint(x: 470, y: 220),
                           controlPoint2: CGPoint(x: 455, y: 245))
            africa.addCurve(to: CGPoint(x: 485, y: 300),
                           controlPoint1: CGPoint(x: 462, y: 278),
                           controlPoint2: CGPoint(x: 472, y: 292))
            // Southern tip
            africa.addCurve(to: CGPoint(x: 525, y: 370),
                           controlPoint1: CGPoint(x: 495, y: 330),
                           controlPoint2: CGPoint(x: 510, y: 355))
            africa.addCurve(to: CGPoint(x: 545, y: 365),
                           controlPoint1: CGPoint(x: 532, y: 372),
                           controlPoint2: CGPoint(x: 539, y: 370))
            // Eastern horn (Somalia)
            africa.addCurve(to: CGPoint(x: 560, y: 295),
                           controlPoint1: CGPoint(x: 555, y: 345),
                           controlPoint2: CGPoint(x: 562, y: 318))
            // Narrow top
            africa.addCurve(to: CGPoint(x: 525, y: 200),
                           controlPoint1: CGPoint(x: 557, y: 260),
                           controlPoint2: CGPoint(x: 545, y: 225))
            africa.addCurve(to: CGPoint(x: 480, y: 200),
                           controlPoint1: CGPoint(x: 510, y: 195),
                           controlPoint2: CGPoint(x: 495, y: 195))
            africa.close()
            ctx.addPath(africa.cgPath)
            ctx.fillPath()

            // Europe (smaller, connected to Asia)
            let europe = UIBezierPath()
            europe.move(to: CGPoint(x: 490, y: 140))
            europe.addCurve(to: CGPoint(x: 540, y: 155),
                           controlPoint1: CGPoint(x: 510, y: 142),
                           controlPoint2: CGPoint(x: 528, y: 148))
            europe.addCurve(to: CGPoint(x: 535, y: 190),
                           controlPoint1: CGPoint(x: 545, y: 168),
                           controlPoint2: CGPoint(x: 542, y: 182))
            europe.addCurve(to: CGPoint(x: 490, y: 185),
                           controlPoint1: CGPoint(x: 520, y: 192),
                           controlPoint2: CGPoint(x: 505, y: 190))
            europe.close()
            ctx.addPath(europe.cgPath)
            ctx.fillPath()

            // Asia (massive, realistic)
            let asia = UIBezierPath()
            asia.move(to: CGPoint(x: 540, y: 150))
            // Northern edge
            asia.addCurve(to: CGPoint(x: 680, y: 120),
                         controlPoint1: CGPoint(x: 590, y: 135),
                         controlPoint2: CGPoint(x: 640, y: 125))
            asia.addCurve(to: CGPoint(x: 780, y: 145),
                         controlPoint1: CGPoint(x: 720, y: 115),
                         controlPoint2: CGPoint(x: 755, y: 128))
            // Eastern edge (Pacific)
            asia.addCurve(to: CGPoint(x: 820, y: 210),
                         controlPoint1: CGPoint(x: 800, y: 165),
                         controlPoint2: CGPoint(x: 815, y: 190))
            asia.addCurve(to: CGPoint(x: 790, y: 280),
                         controlPoint1: CGPoint(x: 823, y: 240),
                         controlPoint2: CGPoint(x: 810, y: 265))
            // Southeast Asia
            asia.addCurve(to: CGPoint(x: 720, y: 310),
                         controlPoint1: CGPoint(x: 770, y: 292),
                         controlPoint2: CGPoint(x: 745, y: 305))
            // India subcontinent
            asia.addCurve(to: CGPoint(x: 650, y: 300),
                         controlPoint1: CGPoint(x: 695, y: 315),
                         controlPoint2: CGPoint(x: 670, y: 312))
            asia.addCurve(to: CGPoint(x: 630, y: 270),
                         controlPoint1: CGPoint(x: 638, y: 292),
                         controlPoint2: CGPoint(x: 632, y: 280))
            // Western edge (connects to Europe)
            asia.addCurve(to: CGPoint(x: 560, y: 220),
                         controlPoint1: CGPoint(x: 620, y: 250),
                         controlPoint2: CGPoint(x: 590, y: 235))
            asia.addCurve(to: CGPoint(x: 540, y: 150),
                         controlPoint1: CGPoint(x: 545, y: 200),
                         controlPoint2: CGPoint(x: 538, y: 175))
            asia.close()
            ctx.addPath(asia.cgPath)
            ctx.fillPath()

            // Australia (smaller, isolated in southern hemisphere)
            let australia = UIBezierPath()
            australia.move(to: CGPoint(x: 750, y: 340))
            australia.addCurve(to: CGPoint(x: 810, y: 355),
                              controlPoint1: CGPoint(x: 775, y: 338),
                              controlPoint2: CGPoint(x: 795, y: 345))
            australia.addCurve(to: CGPoint(x: 805, y: 385),
                              controlPoint1: CGPoint(x: 815, y: 368),
                              controlPoint2: CGPoint(x: 813, y: 380))
            australia.addCurve(to: CGPoint(x: 755, y: 375),
                              controlPoint1: CGPoint(x: 790, y: 388),
                              controlPoint2: CGPoint(x: 770, y: 383))
            australia.addCurve(to: CGPoint(x: 750, y: 340),
                              controlPoint1: CGPoint(x: 748, y: 365),
                              controlPoint2: CGPoint(x: 746, y: 350))
            australia.close()
            ctx.addPath(australia.cgPath)
            ctx.fillPath()

            // Eastern Russia/Siberia (continuation of Asia)
            let easternAsia = UIBezierPath()
            easternAsia.move(to: CGPoint(x: 820, y: 155))
            easternAsia.addCurve(to: CGPoint(x: 920, y: 180),
                                controlPoint1: CGPoint(x: 860, y: 150),
                                controlPoint2: CGPoint(x: 895, y: 165))
            easternAsia.addCurve(to: CGPoint(x: 945, y: 240),
                                controlPoint1: CGPoint(x: 938, y: 200),
                                controlPoint2: CGPoint(x: 948, y: 222))
            easternAsia.addCurve(to: CGPoint(x: 895, y: 270),
                                controlPoint1: CGPoint(x: 940, y: 255),
                                controlPoint2: CGPoint(x: 918, y: 265))
            easternAsia.addCurve(to: CGPoint(x: 850, y: 245),
                                controlPoint1: CGPoint(x: 875, y: 268),
                                controlPoint2: CGPoint(x: 860, y: 258))
            easternAsia.addCurve(to: CGPoint(x: 820, y: 155),
                                controlPoint1: CGPoint(x: 835, y: 220),
                                controlPoint2: CGPoint(x: 820, y: 185))
            easternAsia.close()
            ctx.addPath(easternAsia.cgPath)
            ctx.fillPath()

            // Japan archipelago
            let japan = UIBezierPath()
            japan.move(to: CGPoint(x: 860, y: 220))
            japan.addCurve(to: CGPoint(x: 875, y: 245),
                          controlPoint1: CGPoint(x: 865, y: 228),
                          controlPoint2: CGPoint(x: 872, y: 238))
            japan.addCurve(to: CGPoint(x: 868, y: 252),
                          controlPoint1: CGPoint(x: 873, y: 248),
                          controlPoint2: CGPoint(x: 870, y: 250))
            japan.addCurve(to: CGPoint(x: 856, y: 235),
                          controlPoint1: CGPoint(x: 863, y: 246),
                          controlPoint2: CGPoint(x: 858, y: 240))
            japan.close()
            ctx.addPath(japan.cgPath)
            ctx.fillPath()

            // New Zealand (small southern islands)
            let newZealand1 = UIBezierPath(ovalIn: CGRect(x: 885, y: 395, width: 25, height: 18))
            ctx.addPath(newZealand1.cgPath)
            ctx.fillPath()

            let newZealand2 = UIBezierPath(ovalIn: CGRect(x: 895, y: 415, width: 22, height: 16))
            ctx.addPath(newZealand2.cgPath)
            ctx.fillPath()

            // Pacific islands (smaller, more scattered)
            let island1 = UIBezierPath(ovalIn: CGRect(x: 920, y: 280, width: 18, height: 12))
            ctx.addPath(island1.cgPath)
            ctx.fillPath()

            let island2 = UIBezierPath(ovalIn: CGRect(x: 960, y: 310, width: 15, height: 10))
            ctx.addPath(island2.cgPath)
            ctx.fillPath()

            // Greenland (left edge, northern)
            let greenland = UIBezierPath()
            greenland.move(to: CGPoint(x: 0, y: 100))
            greenland.addCurve(to: CGPoint(x: 70, y: 115),
                              controlPoint1: CGPoint(x: 25, y: 98),
                              controlPoint2: CGPoint(x: 50, y: 105))
            greenland.addCurve(to: CGPoint(x: 85, y: 155),
                              controlPoint1: CGPoint(x: 80, y: 128),
                              controlPoint2: CGPoint(x: 88, y: 143))
            greenland.addCurve(to: CGPoint(x: 60, y: 175),
                              controlPoint1: CGPoint(x: 82, y: 165),
                              controlPoint2: CGPoint(x: 72, y: 172))
            greenland.addCurve(to: CGPoint(x: 0, y: 145),
                              controlPoint1: CGPoint(x: 40, y: 178),
                              controlPoint2: CGPoint(x: 15, y: 165))
            greenland.close()
            ctx.addPath(greenland.cgPath)
            ctx.fillPath()

            // Alaska (right edge continuation of North America)
            let alaska = UIBezierPath()
            alaska.move(to: CGPoint(x: size.width, y: 125))
            alaska.addCurve(to: CGPoint(x: size.width - 60, y: 145),
                           controlPoint1: CGPoint(x: size.width - 20, y: 128),
                           controlPoint2: CGPoint(x: size.width - 38, y: 138))
            alaska.addCurve(to: CGPoint(x: size.width - 50, y: 175),
                           controlPoint1: CGPoint(x: size.width - 65, y: 158),
                           controlPoint2: CGPoint(x: size.width - 58, y: 168))
            alaska.addCurve(to: CGPoint(x: size.width, y: 165),
                           controlPoint1: CGPoint(x: size.width - 35, y: 178),
                           controlPoint2: CGPoint(x: size.width, y: 172))
            alaska.close()
            ctx.addPath(alaska.cgPath)
            ctx.fillPath()

            // North pole ice cap
            let northPole = UIBezierPath()
            northPole.move(to: CGPoint(x: 0, y: 50))
            northPole.addLine(to: CGPoint(x: size.width, y: 50))
            northPole.addLine(to: CGPoint(x: size.width, y: 0))
            northPole.addLine(to: CGPoint(x: 0, y: 0))
            northPole.close()
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.addPath(northPole.cgPath)
            ctx.fillPath()

            // South pole ice cap
            let southPole = UIBezierPath()
            southPole.move(to: CGPoint(x: 0, y: size.height - 50))
            southPole.addLine(to: CGPoint(x: size.width, y: size.height - 50))
            southPole.addLine(to: CGPoint(x: size.width, y: size.height))
            southPole.addLine(to: CGPoint(x: 0, y: size.height))
            southPole.close()
            ctx.addPath(southPole.cgPath)
            ctx.fillPath()
        }
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

            Text("Animated Globe with Price Tag")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
