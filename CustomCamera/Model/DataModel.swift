//
//  DataModel.swift
//  CustomCamera
//
//  Created by window1 on 7/5/24.
//

import Foundation
import SwiftUI

//우선 사진첩에 접근하는 부분만 제작
class DataModel: ObservableObject {
    
    let photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
    
    @Published var viewfinderImage: Image?
    @Published var thumbnailImage: Image?
    
    
    var isPhotosLoaded = false

    func savePhoto(imageData: Data) {
        Task {
            do {
                try await photoCollection.addImage(imageData)
                print("Added image data to photo colleciton.")
            } catch let error {
                print("Faild to Add image to photo collection : \(error.localizedDescription)")
            }
        }
    }
    
    func loadPhotos() async {
        guard !isPhotosLoaded else { return }
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else { return }
        Task {
            do {
                try await self.photoCollection.load()
                //썸네일 로드 코드
            } catch let error {
                print("Photo library access was not authroized \(error.localizedDescription)")
            }
            self.isPhotosLoaded = true
        }
    }
    
    func loadThumbnail() async {
        guard let asset = photoCollection.photoAssets.first else { return }
        await photoCollection.cache.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256)) { result in
            if let result = result {
                Task { @MainActor in
                    self.thumbnailImage = result.image
                }
            }
        }
    }
}
