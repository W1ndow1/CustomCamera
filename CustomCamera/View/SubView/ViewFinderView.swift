//
//  ViewFinderView.swift
//  CustomCamera
//
//  Created by window1 on 7/7/24.
//

import SwiftUI

struct ViewFinderView: View {
    @Binding var image: Image?
    var body: some View {
        GeometryReader { geo in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

#Preview {
    ViewFinderView(image: .constant(Image(systemName: "arrow.circlepath")))
}
