//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Eugen on 25/10/14.
//  Copyright (c) 2014 olgen. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData

class FeedViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    @IBOutlet var collectoinView: UICollectionView!

    var feedArray:[AnyObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        let context:NSManagedObjectContext = appDelegate.managedObjectContext!
        var error = NSErrorPointer()
        feedArray = context.executeFetchRequest(request, error: error)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func snapBarButtonTapped(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var cameraController = UIImagePickerController()
            cameraController.delegate = self
            cameraController.sourceType = .Camera
            cameraController.mediaTypes = [kUTTypeImage]
            cameraController.allowsEditing = false
            self.presentViewController(cameraController, animated: true, completion: nil)
        } else if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = .PhotoLibrary
            photoLibraryController.mediaTypes = [kUTTypeImage]
            photoLibraryController.allowsEditing = false
            self.presentViewController(photoLibraryController, animated: true, completion: nil)

        } else {
            NSLog("No camera available!")
            var alertViewController = UIAlertController(title: "Alert", message: "Your device does not support the camera!", preferredStyle: .Alert)
            alertViewController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }

    // UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        println(image)
        let imageData  = UIImageJPEGRepresentation(image, 1.0)

        let ctx = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: ctx!)

        let feedItem = FeedItem(entity: entityDescription!,
            insertIntoManagedObjectContext: ctx!)

        feedItem.image = imageData
        feedItem.caption = "Test caption"

        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()

        feedArray.append(feedItem)
        self.collectoinView.reloadData()
        self.dismissViewControllerAnimated(true, completion: nil)
    }


    // UICOllectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
    }

    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        let item = feedArray[indexPath.row] as FeedItem
        cell.imageView.image = UIImage(data: item.image)
        cell.label.text = item.caption

        return cell
    }

    // UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = feedArray[indexPath.row] as FeedItem
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = item
        self.navigationController?.pushViewController(filterVC, animated: false)
    }

}
