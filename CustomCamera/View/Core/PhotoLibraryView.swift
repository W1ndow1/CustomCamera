//
//  PhotoLibraryView.swift
//  CustomCamera
//
//  Created by window1 on 6/14/24.
//

import SwiftUI
import PhotosUI

struct PhotoLibraryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ImageGridView()
                .navigationTitle("라이브러리")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .imageScale(.large)
                                .foregroundStyle(.foreground)
                        }
                    }
                }
        }
    }
}

#Preview {
    PhotoLibraryView()
}

struct ImageGridView: View {
    @StateObject var model = PhotoLibrary()
    
    var body: some View {
        NavigationStack {
            if model.isAuthorizedPhotoLibaray {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(model.images, id: \.self, content: { image in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipped()
                        })
                    }
                }
            }
        }
        .onAppear {
            model.checkPhotoLibarayAuthorization()
        }
    }
}

