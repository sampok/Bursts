//
//  DetailViewController.swift
//  Bursts
//
//  Created by Sampo Karjalainen on 6/23/16.
//  Copyright © 2016 Team Yellow 3. All rights reserved.
//

import UIKit
import Photos

class DetailViewController: UIViewController {
    
    @IBOutlet weak var detailImageView: UIImageView!
    
    var detailAnimImage: UIImage!
    var burstId: String = ""
    var burstImages: [UIImage?]!
    var currentFrame: Int = 0
    var assets: PHFetchResult!
    var animTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assets = burstsManager.getBurstImages(burstId)
        animTimer = NSTimer.scheduledTimerWithTimeInterval(
            0.05,
            target: self,
            selector: #selector(self.animate),
            userInfo: nil,
            repeats: true
        )
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        animTimer.invalidate()
        animTimer = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func animate() {
        burstsManager.imageManager.requestImageForAsset(
            assets[currentFrame] as! PHAsset,
            targetSize: CGSize(width: view.frame.size.width, height: view.frame.size.height),
            contentMode: .AspectFit,
            options: nil
        ) {result, info in
            if info![PHImageResultIsDegradedKey] === false {
                let image = result!
                dispatch_async(dispatch_get_main_queue(), {
                    self.detailImageView.image = image
                })
            }
        }
        
        currentFrame += 1
        if currentFrame >= assets.count {
            currentFrame = 0
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
