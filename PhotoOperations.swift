//
//  PhotoOperations.swift
//  ClassicPhotos
//
//  Created by Joshua Winskill on 10/7/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit

enum PhotoRecordState {
    case New, Downloaded, Filtered, Failed
}

class PhotoRecord {
    let name: String
    let url: NSURL
    var state = PhotoRecordState.New
    var image = UIImage(named: "Placeholder")
    
    init(name: String, url: NSURL) {
        self.name = name
        self.url = url
    }
}

class PendingOperations {
    lazy var downloadsInProgress = Dictionary<NSIndexPath, NSOperation>()
    lazy var downloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var filtrationsInProgress = Dictionary<NSIndexPath, NSOperation>()
    lazy var filtrationQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Filtration Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

class ImageDownloader: NSOperation {
    // 1
    let photoRecord: PhotoRecord
    
    // 2
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    // 3
    override func main() {
        autoreleasepool {
            
            // 4
            if self.cancelled {
                return
            }
            // 5
            let imageData = NSData(contentsOfURL: self.photoRecord.url)
            
            // 6
            if self.cancelled {
                return
            }
            
            // 7
            if imageData.length > 0 {
                self.photoRecord.image = UIImage(data: imageData)
                self.photoRecord.state = .Downloaded
            }
            else
            {
                self.photoRecord.state = .Failed
                self.photoRecord.image = UIImage(named: "Failed")
            }
        }
    }
}

class ImageFiltration: NSOperation {
    
    let photoRecord: PhotoRecord
    
    init (photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    func applySepiaFilter (image: UIImage) -> UIImage? {
        let inputImage = CIImage(data: UIImagePNGRepresentation(image))
        
        if self.cancelled {
            return nil
        }
        let context = CIContext(options: nil)
        let filter = CIFilter(name: "CISepiaTone")
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey:"inputIntensity")
        let outputImage = filter.outputImage
        
        if self.cancelled {
            return nil
        }
        
        let outImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        let returnImage = UIImage(CGImage: outImage)
        return returnImage
    }
    
    override func main() {
        autoreleasepool {
            
            if self.cancelled {
                return
            }
            
            if self.photoRecord.state != .Downloaded {
                return
            }
            
            let filteredImage = self.applySepiaFilter(self.photoRecord.image)
                
            if let filteredImage = self.applySepiaFilter(self.photoRecord.image) {
                self.photoRecord.image = filteredImage
                self.photoRecord.state = .Filtered
            }
        }
    }
}

