//
//  CustomCameraApp.swift
//  CustomCamera
//
//  Created by window1 on 3/29/24.
//

import SwiftUI

@main

struct CustomCameraApp: App {
//    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
//    @State private var degToFaceUp: Double = 0
    init() {
        UINavigationBar.applyCustomAppearance()
    }
    var body: some Scene {
        WindowGroup {
            //ContentView(degToFaceUp: 0)
            CameraView()
            /*
            ContentView(degToFaceUp: degToFaceUp)
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        var offset: Int = 0
                        switch UIDevice.current.orientation {
                        case .portrait:
                            offset = 0
                        case .portraitUpsideDown:
                            offset = 2
                        case .landscapeLeft:
                            offset = 1
                        case .landscapeRight:
                            offset = -1
                        case .unknown:
                            offset = 0
                        case .faceUp:
                            offset = 0
                        case .faceDown:
                            offset = 0
                        @unknown default:
                            print("** New UIDeviceOrientation, add case to the degToFaceTop")
                            offset = 0
                        }
                        degToFaceUp = Double(offset) * 90.0
                    }
             */
        }
    }
}

fileprivate extension UINavigationBar {
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
