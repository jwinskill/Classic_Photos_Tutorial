//
//  ListViewController.swift
//  ClassicPhotos
//
//  Created by Richard Turton on 03/07/2014.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit
import CoreImage

let dataSourceURL = NSURL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class ListViewController: UITableViewController {
  
    var photos = [PhotoRecord]()
    let pendingOperations = PendingOperations()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }
    
    func fetchPhotoDetails() {
        let request = NSURLRequest(URL: dataSourceURL)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { response, data, error in
            if data != nil {
                let datasourceDictionary = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption: .Immutable, format: nil, errorDescription: nil) as NSDictionary
                
                for (key: AnyObject, value: AnyObject) in datasourceDictionary {
                    let name = key as? String
                    let urlString = value as? String
                    if name != nil && urlString != nil {
                        let photoRecord = PhotoRecord(name: name!, url: NSURL(string: urlString!))
                        self.photos.append(photoRecord)
                    }
                }
                
                self.tableView.reloadData()
            }
            
            if error != nil {
                let alert = UIAlertView(title: "OOPS!", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // #pragma mark - Table view data source
  
  override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier", forIndexPath: indexPath) as UITableViewCell
    
    // 1
    if cell.accessoryView == nil {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        cell.accessoryView = indicator
    }
    let indicator = cell.accessoryView as UIActivityIndicatorView
    
    // 2
    let photoDetails = photos[indexPath.row]
    
    // 3
    cell.textLabel?.text = photoDetails.name
    cell.imageView?.image = photoDetails.image
    
    // 4
    switch (photoDetails.state) {
    case .Filtered:
        indicator.stopAnimating()
    case .Failed:
        indicator.stopAnimating()
        cell.textLabel?.text = "Failed to Load"
    case .New, .Downloaded:
        indicator.startAnimating()
        self.startOperationsForPhotoRecord(photoDetails,indexPath: indexPath)
        }
    return cell
    }
    
    func startOperationsForPhotoRecord (photoDetails: PhotoRecord, indexPath: NSIndexPath) {
        switch (photoDetails.state) {
        case .New:
            startDownloadForRecord (photoDetails, indexPath: indexPath)
        case .Downloaded:
            startFiltrationForRecord(photoDetails, indexPath: indexPath)
        default:
            NSLog("do nothing")
        }
    }
    
    func startDownloadForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath) {
        // 1
        if let downloadOperation = pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        // 2
        let downloader = ImageDownloader(photoRecord: photoDetails)
        // 3
        downloader.completionBlock = {
            if downloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        // 4
        pendingOperations.downloadsInProgress[indexPath] = downloader
        // 5
        pendingOperations.filtrationQueue.addOperation(downloader)
    }

    func startFiltrationForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath) {
        if let filterOperation = pendingOperations.filtrationsInProgress[indexPath] {
            return
        }
        
        let filterer = ImageFiltration(photoRecord: photoDetails)
        filterer.completionBlock = {
            if filterer.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.filtrationsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        pendingOperations.filtrationsInProgress[indexPath] = filterer
        pendingOperations.filtrationQueue.addOperation(filterer)
    }
    
    
    
}
