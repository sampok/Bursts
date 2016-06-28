//
//  LibraryViewController.swift
//  Bursts
//
//  Created by Sampo Karjalainen on 6/21/16.
//  Copyright © 2016 Team Yellow 3. All rights reserved.
//

import UIKit

class LibraryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var allBurstIds: [String]!
    var previewSize: CGSize!
    var initialPositionDone = false
    var animatingCells: [BurstPreviewCollectionViewCell]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewSize = CGSize(width: view.frame.size.width * 0.75, height: view.frame.size.height * 0.75)
        collectionView.dataSource = self
        collectionView.delegate = self
        allBurstIds = burstsManager.getAllBursts()
        let vMargin = CGFloat((view.frame.height - previewSize.height)/2)
        let hMargin = CGFloat((view.frame.width - previewSize.width)/2)
        collectionView.contentInset = UIEdgeInsetsMake(vMargin, hMargin, vMargin, hMargin)
    }

    override func viewWillAppear(animated: Bool) {
        startAllAnims()
    }
    
    override func viewDidAppear(animated: Bool) {
        if !initialPositionDone {
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: allBurstIds.count-1, inSection: 0), atScrollPosition: .None, animated: false)
            initialPositionDone = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        stopAllAnims()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if allBurstIds.count == 0 {
            return 1
        } else {
            return allBurstIds.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return previewSize
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // Start animating, put in array
        let burstCell = cell as! BurstPreviewCollectionViewCell
        burstCell.currentFrame = 0
        burstCell.burstAssets = burstsManager.getBurstImages(burstCell.burstId)
        startAnimating(burstCell)
        animatingCells.append(burstCell)
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // Stop animating, remove from array
        let burstCell = cell as! BurstPreviewCollectionViewCell
        stopAnimating(burstCell)
        let index = animatingCells.indexOf(burstCell)
        animatingCells.removeAtIndex(index!)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BurstPreviewCell", forIndexPath: indexPath) as! BurstPreviewCollectionViewCell
        cell.burstId = self.allBurstIds[indexPath.item]
        return cell
    }

    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        scrollToClosest(scrollView)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollToClosest(scrollView)
    }
    
    func scrollToClosest(scrollView: UIScrollView) {
        let currentFloatPosition = (scrollView.contentOffset.x + (view.frame.width - previewSize.width)/2) / (previewSize.width+10)
        let roundedPosition = round(currentFloatPosition)
        let newX = roundedPosition * (previewSize.width+10) - (view.frame.width - previewSize.width)/2
        scrollView.setContentOffset(CGPoint(x: newX, y: scrollView.contentOffset.y), animated: true)
    }
    
    func startAnimating(cell: BurstPreviewCollectionViewCell) {
        cell.animTimer = NSTimer.scheduledTimerWithTimeInterval(
            0.05,
            target: cell,
            selector: #selector(cell.animate),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopAnimating(cell: BurstPreviewCollectionViewCell) {
        cell.animTimer.invalidate()
    }
    
    func startAllAnims() {
        for cell in animatingCells {
            startAnimating(cell)
        }
    }
    
    func stopAllAnims() {
        for cell in animatingCells {
            stopAnimating(cell)
        }
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
