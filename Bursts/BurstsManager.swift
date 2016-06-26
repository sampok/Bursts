//
//  BurstsManager.swift
//  BurstsFetch
//
//  Created by Sampo Karjalainen on 6/19/16.
//  Copyright © 2016 Sampo Karjalainen. All rights reserved.
//

import UIKit
import Photos

// Global object
var burstsManager = BurstsManager()

class BurstsManager: NSObject {
    
    var imageManager: PHCachingImageManager!
    
    override init() {
        super.init()
        self.imageManager = PHCachingImageManager()
    }
    
    func getAllBursts() -> [String] {
        let selectedSmartAlbums = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumBursts, options: nil)
        let burstCollection = selectedSmartAlbums[0] as! PHAssetCollection
        let allBursts = PHAsset.fetchAssetsInAssetCollection(burstCollection, options: nil)
        var ids: [String] = []
        allBursts.enumerateObjectsUsingBlock { (photo, index, stop) in
            ids.append(photo.burstIdentifier!!)
        }
        return ids
    }
    
    func getBurstCoverImage(id: String, size: CGSize, contentMode: PHImageContentMode, callback: (image: UIImage?) -> Void) {
        let coverImage = PHAsset.fetchAssetsWithBurstIdentifier(id, options: nil)
        self.imageManager.requestImageForAsset(
            coverImage[0] as! PHAsset,
            targetSize: size,
            contentMode: contentMode,
            options: nil
        ) {result, info in
            if info![PHImageResultIsDegradedKey] === false { // Gets fired multiple times. Check for full res image.
                callback(image: result!)
            }
        }
    }
    
    func getBurstImages(id: String) -> PHFetchResult {
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
        let burstAssets = PHAsset.fetchAssetsWithBurstIdentifier(id, options: options)
        return burstAssets
    }
}
