//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Eugen on 25/10/14.
//  Copyright (c) 2014 olgen. All rights reserved.
//

import UIKit
import CoreImage


class FilterViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate
{

    var thisFeedItem: FeedItem!

    var collectionView: UICollectionView!

    let kIntensity = 0.7

    var filters:[CIFilter] = []

    var context = CIContext(options: nil)

    let placeHolderImage = UIImage(named: "Placeholder")

    let tmp = NSTemporaryDirectory()

    override func viewDidLoad() {
        super.viewDidLoad()

        filters = photoFilters()

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()

        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")

        self.view.addSubview(collectionView)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }

    func collectionView(collectionView: UICollectionView,
       cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell

        let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        cell.imageView.image = placeHolderImage
        
        // run the calc in the background
        dispatch_async(filterQueue, { () -> Void in
            let filterImage = self.getCachedImage(indexPath.row)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
            })
        })
        
        return cell
    }

    // UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])

        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        let thumbnailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbnail = thumbnailData

        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)
    }

    // HelperFunction

    func photoFilters() -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")

        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)

        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)

        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")

        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)

        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)

        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)

        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }

    func filteredImageFromImage(imageData: NSData, filter: CIFilter) -> UIImage {
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage

        let extent = filteredImage.extent()
        let cgImage:CGImageRef = context.createCGImage(filteredImage, fromRect: extent)

        let finalImage = UIImage(CGImage: cgImage)
//        let finalImage = UIImage(CIImage: filteredImage)

        return finalImage!
    }

    // caching functions
    func cacheImage(imageNumber: Int){
        let uniquePath = cacheFilePath(imageNumber)
        if !fileExists(uniquePath) {
            let data = self.thisFeedItem.thumbnail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            println("Writing image \(imageNumber) to path \(uniquePath)")
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }

    func getCachedImage(imageNumber: Int) -> UIImage {
        let uniquePath = cacheFilePath(imageNumber)
        if !fileExists(uniquePath) {
            self.cacheImage(imageNumber)
        }
        return UIImage(contentsOfFile: uniquePath)!
    }

    func fileExists(path: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    func cacheFilePath(imageNumber: Int) -> String {
        return tmp.stringByAppendingPathComponent("\(imageNumber)")
    }

}