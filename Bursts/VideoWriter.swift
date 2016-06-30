//
//  VideoWriter.swift
//  Bursts
//
//  Created by Sampo Karjalainen on 6/28/16.
//  Copyright © 2016 Team Yellow 3. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class VideoWriter: NSObject {
    
    func writeVideo(assets: PHFetchResult, videoSize: CGSize, fps: Int32) {
        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let filePath = paths[0].URLByAppendingPathComponent("export.mov")
        do {
            try NSFileManager.defaultManager().removeItemAtURL(filePath)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
        // This should be really done in a background thread
        self.writeImagesAsMovie(assets, videoPathURL: filePath, videoSize: videoSize, videoFPS: fps)
    }

    func writeImagesAsMovie(assets: PHFetchResult, videoPathURL: NSURL, videoSize: CGSize, videoFPS: Int32) {
        // Create AVAssetWriter to write video
        guard let assetWriter = createAssetWriter(videoPathURL, size: videoSize) else {
            print("Error converting images to video: AVAssetWriter not created")
            return
        }
        
        // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
        let writerInput = assetWriter.inputs.filter{ $0.mediaType == AVMediaTypeVideo }.first!
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String : videoSize.width,
            kCVPixelBufferHeightKey as String : videoSize.height,
            ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        
        // Start writing session
        assetWriter.startWriting()
        assetWriter.startSessionAtSourceTime(kCMTimeZero)
        if (pixelBufferAdaptor.pixelBufferPool == nil) {
            print("Error converting images to video: pixelBufferPool nil after starting session")
            return
        }
        
        // -- Create queue for <requestMediaDataWhenReadyOnQueue>
        let mediaQueue = dispatch_queue_create("mediaInputQueue", nil)
        
        // -- Set video parameters
        let frameDuration = CMTimeMake(1, videoFPS)
        var frameCount = 0
        
        // -- Add images to video
        let numImages = assets.count
        writerInput.requestMediaDataWhenReadyOnQueue(mediaQueue, usingBlock: { () -> Void in
            // Append unadded images to video but only while input ready
            while (writerInput.readyForMoreMediaData && frameCount < numImages) {
                autoreleasepool {
                    let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
                    let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                    
                    let options = PHImageRequestOptions()
                    options.synchronous = true
                    burstsManager.imageManager.requestImageForAsset(
                        assets[frameCount] as! PHAsset,
                        targetSize: videoSize,
                        contentMode: .AspectFit,
                        options: options
                    ) {result, info in
                        let resized = self.resizeImage(result!, targetSize: videoSize)
                        if !self.appendPixelBufferForImageAtURL(resized, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                            print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                            return
                        }
                        frameCount += 1
                    }
                }
                
            }
            
            // No more images to add? End video.
            if (frameCount >= numImages) {
                writerInput.markAsFinished()
                assetWriter.finishWritingWithCompletionHandler {
                    if (assetWriter.error != nil) {
                        print("Error converting images to video: \(assetWriter.error)")
                    } else {
                        self.saveVideoToLibrary(videoPathURL)
                        print("Converted images to movie @ \(videoPathURL)")
                    }
                }
            }
        })
    }


    func createAssetWriter(pathURL: NSURL, size: CGSize) -> AVAssetWriter? {
        
        // Return new asset writer or nil
        do {
            // Create asset writer
            let newWriter = try AVAssetWriter(URL: pathURL, fileType: AVFileTypeMPEG4)
            
            // Define settings for video input
            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecH264,
                AVVideoWidthKey  : size.width,
                AVVideoHeightKey : size.height,
                ]
            
            // Add video input to writer
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            newWriter.addInput(assetWriterVideoInput)
            
            // Return writer
            print("Created asset writer for \(size.width)x\(size.height) video")
            return newWriter
        } catch {
            print("Error creating asset writer: \(error)")
            return nil
        }
    }


    func appendPixelBufferForImageAtURL(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        
        autoreleasepool {
            if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )
                
                if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                    pixelBufferPointer.destroy()
                } else {
                    NSLog("Error: Failed to allocate pixel buffer from pool")
                }
                
                pixelBufferPointer.dealloc(1)
            }
        }
        
        return appendSucceeded
    }


    func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBufferRef) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create CGBitmapContext
        let context = CGBitmapContextCreate(
            pixelData,
            Int(image.size.width),
            Int(image.size.height),
            8,
            CVPixelBufferGetBytesPerRow(pixelBuffer),
            rgbColorSpace,
            CGImageAlphaInfo.PremultipliedFirst.rawValue
        )
        
        // Draw image into context
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }


    func saveVideoToLibrary(videoURL: NSURL) {
        PHPhotoLibrary.requestAuthorization { status in
            // Return if unauthorized
            guard status == .Authorized else {
                print("Error saving video: unauthorized access")
                return
            }
            
            // If here, save video to library
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL)
            }) { success, error in
                if !success {
                    print("Error saving video: \(error)")
                }
            }
        }
    }
    
}