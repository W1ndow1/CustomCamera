//
//  PhotoCollectionView.swift
//  CustomCamera
//
//  Created by window1 on 6/24/24.
//

import SwiftUI

struct PhotoCollectionView: View {
    @ObservedObject var photoCollection: PhotoLibrary
    @Environment(\.displayScale) private var displayScale
    
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    PhotoCollectionView(photoCollection: .init())
}
