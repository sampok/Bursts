//
//  BurstPreviewCollectionViewCell.swift
//  Bursts
//
//  Created by Sampo Karjalainen on 6/21/16.
//  Copyright © 2016 Team Yellow 3. All rights reserved.
//

import UIKit
import Photos

class BurstPreviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    var burstId: String! = ""
    var currentFrame = 0
    var burstAssets: PHFetchResult!
    var animTimer: NSTimer!
    
    func animate() {
        burstsManager.imageManager.requestImageForAsset(
            burstAssets[currentFrame] as! PHAsset,
            targetSize: CGSize(width: previewImageView.frame.size.width/2, height: previewImageView.frame.size.height/2),
            contentMode: .AspectFit,
            options: nil
        ) {result, info in
            if info![PHImageResultIsDegradedKey] === false {
                self.previewImageView.image = result
            }
        }
        
        currentFrame += 1
        if currentFrame >= burstAssets.count {
            currentFrame = 0
        }
    }
}