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
    
    var allBurstIds: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        allBurstIds = burstsManager.getAllBursts()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if allBurstIds.count == 0 {
            return 1
        } else {
            return allBurstIds.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BurstPreviewCell", forIndexPath: indexPath) as! BurstPreviewCollectionViewCell
        burstsManager.getBurstCoverImage(allBurstIds[indexPath.item], size: CGSize(width: 240, height: 320), contentMode: .AspectFit, callback: { (image) in
            cell.previewImageView.image = image
            cell.burstId = self.allBurstIds[indexPath.item]
        })
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
     // MARK: - Navigation
     
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        let detailVC = segue.destinationViewController as! DetailViewController
        let cell = sender as! BurstPreviewCollectionViewCell
        detailVC.burstId = cell.burstId
        
     }
    
    
}
