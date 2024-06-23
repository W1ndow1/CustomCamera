//
//  AlbumViewModel.swift
//  CustomCamera
//
//  Created by window1 on 6/22/24.
//

import Foundation
import Photos

class PhotoGridViewModel: NSObject, ObservableObject {
    
    @Published var assets: PHFetchResult<PHAsset>
    
    init(assets: PHFetchResult<PHAsset>) {
        self.assets = assets
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension PhotoGridViewModel: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            if let changeDetail = changeInstance.changeDetails(for: self.assets) {
                self.assets = changeDetail.fetchResultAfterChanges
            }
                
        }
    }
}
