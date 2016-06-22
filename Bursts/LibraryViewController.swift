//
//  LibraryViewController.swift
//  Bursts
//
//  Created by Sampo Karjalainen on 6/21/16.
//  Copyright © 2016 Team Yellow 3. All rights reserved.
//

import UIKit

class LibraryViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var burstsManager = BurstsManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let burstCount = burstsManager.getAllBursts().count
        if burstCount == 0 {
            return 1
        } else {
            return burstCount
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BurstPreviewCell", forIndexPath: indexPath) as! BurstPreviewCollectionViewCell
        let allBursts = burstsManager.getAllBursts()
        burstsManager.getBurstCoverImage(allBursts[indexPath.item], size: CGSize(width: 180, height: 240), contentMode: .AspectFit, callback: { (image) in
            cell.previewImageView.image = image
        })
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
