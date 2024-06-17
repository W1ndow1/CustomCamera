//
//  PhotoLibrary.swift
//  CustomCamera
//
//  Created by window1 on 6/15/24.
//

import Foundation
import Photos
import UIKit

class PhotoLibrary: ObservableObject {
    
    private var allphotos: PHFetchResult<PHAsset>!
    
    @Published var images: [UIImage] = []
    @Published var isAuthorizedPhotoLibaray: Bool = false
    
    init() {
        checkPhotoLibarayAuthorization()
    }
    
    func checkPhotoLibarayAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            isAuthorizedPhotoLibaray = true
            fetchAllPhoto()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.isAuthorizedPhotoLibaray = true
                        self.fetchAllPhoto()
                    }
                }
            }
            
        default:
            isAuthorizedPhotoLibaray = false
        }
    }
    
    func fetchAllPhoto() {
        //사진 가져오는 옵션
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allphotos = PHAsset.fetchAssets(with: fetchOptions)
        
        //실제 파일 가져오기
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        fetchResult.enumerateObjects { asset, _, _ in
            self.requestImage(for: asset)
        }
    }
    
    func requestImage(for asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) {
            image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.images.append(image)
                }
            }
        }
    }
}
