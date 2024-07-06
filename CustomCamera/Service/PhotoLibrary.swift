//
//  PhotoLibrary.swift
//  CustomCamera
//
//  Created by window1 on 6/15/24.
//

import Foundation
import Photos
import UIKit

enum AlbumSectionType: Int {
    case all, smartAlbums, userCollections
    
    var description: String {
        switch self {
        case .all: return "All Photos"
        case .smartAlbums: return "Smart Albums"
        case .userCollections: return "User Collections"
        }
    }
}

class PhotoLibrary: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var scale: CGFloat? = nil
    @Published var photos: [PHAsset] = []
    @Published var isAuthorized = false
    fileprivate let imageManager = PHCachingImageManager()
    
    @Published var allPhotos = PHFetchResult<PHAsset>()
    @Published var smartAlbums = PHFetchResult<PHAssetCollection>()
    @Published var userCollections = PHFetchResult<PHAssetCollection>()
    @Published var section: [AlbumSectionType] = [.all, .smartAlbums, .userCollections]
    

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func checkPermissionAndFetchAssets() async {
        let granted = await requestPermission()
        if granted {
            DispatchQueue.main.async {
                self.fetchAsset()
            }
        }
    }
    
    private  func requestPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited :
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }
    
    //각각 항목에 PHfetchResult 오브젝트 만들기
    func fetchAsset() {
        let  allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        PHPhotoLibrary.shared().register(self)
    }
    
    static func checkAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            
        case .notDetermined:
            print("Photo library access authroized")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        case .restricted:
            print("Photo library access restricted")
            return false
        case .denied:
            print("Photo library access denied")
            return false
        case .authorized:
            print("Photo library access authorized")
            return true
        case .limited:
            print("Photo library access limited")
            return false
        @unknown default:
            return false
        }
    }
    
    //MARK: - 이전코드
    func checkPhotoLibarayAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            isAuthorized = true
            loadPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.isAuthorized = true
                        self?.loadPhotos()
                    }
                }
            }
        default:
            break
        }
    }

    func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.photos = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))
        
        let assets = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))
        let targetSize = CGSize(width: 100, height: 100)
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func requestImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping(UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            completion(image)
        })
    }
    
    func loadAssetImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping(UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            completion(image)
        })
    }
}

extension PhotoLibrary {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            if let changeDetail = changeInstance.changeDetails(for: allPhotos) {
                allPhotos = changeDetail.fetchResultAfterChanges
            }
            if let changeDetail = changeInstance.changeDetails(for: smartAlbums) {
                smartAlbums = changeDetail.fetchResultAfterChanges
            }
            if let changeDetail = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetail.fetchResultAfterChanges
            }
        }
    }
    
}
