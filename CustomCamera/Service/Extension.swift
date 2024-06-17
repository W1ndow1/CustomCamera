//
//  Extension.swift
//  CustomCamera
//
//  Created by window1 on 5/20/24.
//

import Foundation
import SwiftUI

extension View {
    func viewToImage(view: some View) -> UIImage {
        var image = UIImage()
        let controller = UIHostingController(rootView: view)
        if let view = controller.view {
            let contentSize = view.intrinsicContentSize
            view.bounds = CGRect(origin: .zero, size: contentSize)
            view.backgroundColor = .clear
            view.sizeToFit()
            let renderer = UIGraphicsImageRenderer(size: contentSize)
            image = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }
        return image
    }
    
    func viewRotationEffect(deg: Double) -> some View{
        self.rotationEffect(Angle(degrees: deg))
            .animation(.easeInOut(duration: 0.5), value: deg)
    }
}

extension UIDeviceOrientation {
    var videoRotationAngel: CGFloat {
        switch self {
        case .landscapeLeft:
            0
        case .portrait:
            90
        case .landscapeRight :
            180
        case .portraitUpsideDown :
            270
        default:
            90
        }
    }
}
enum LivePhotoMode {
    case on
    case off
}
