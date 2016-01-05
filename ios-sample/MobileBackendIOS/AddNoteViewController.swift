//
//  ViewController.swift
//  MobileBackendIOS
//

import Foundation
import UIKit
import MobileCoreServices
import AssetsLibrary

class AddNoteViewController: UIViewController , ELCImagePickerControllerDelegate{
    
    @IBOutlet weak var headlineTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var processView: UIProgressView!
    
    @IBOutlet weak var labelUploaded: UILabel!
    
    var fileName: String = ""

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let error = NSErrorPointer()
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload"),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch let error1 as NSError {
            error.memory = error1
            print("Creating 'upload' directory failed. Error: \(error)")
        }
        


        MobileBackendApi.sharedInstance.configureNoteApi()
        MobileBackendApi.sharedInstance.configureS3TransferManager()
    }
    
    @IBAction func actionClick(sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "选择操作",
            message: "选择你的操作。",
            preferredStyle: .ActionSheet)
        
        let selectPictureAction = UIAlertAction(
            title: "选择照片",
            style: .Default) { (action) -> Void in
                self.selectPictures()
        }
        alertController.addAction(selectPictureAction)
        
        /*let cancelAllUploadsAction = UIAlertAction(
            title: "Cancel All Uploads",
            style: .Default) { (action) -> Void in
                self.cancelAllUploads()
        }
        alertController.addAction(cancelAllUploadsAction)*/
        
        let cancelAction = UIAlertAction(
            title: "取消",
            style: .Cancel) { (action) -> Void in }
        alertController.addAction(cancelAction)
        
        self.presentViewController(
            alertController,
            animated: true) { () -> Void in }
    }
    @IBAction func saveNoteButtonPressed(sender: UIButton) {
        if(headlineTextField.text != nil && noteTextField.text != nil) {
            MobileBackendApi.sharedInstance.postNote(headlineTextField.text!, text: noteTextField.text!, s3key:self.fileName, viewController: self)
            headlineTextField.text = nil
            noteTextField.text = nil
        } else {
            print("Error text fields are nil")
        }
    }
    
    func selectPictures() {
        let imagePickerController = ELCImagePickerController()
        imagePickerController.maximumImagesCount = 1
        imagePickerController.imagePickerDelegate = self
        
        self.presentViewController(
            imagePickerController,
            animated: true) { () -> Void in }
    }
    
    /*func cancelAllUploads() {
        for (_, uploadRequest) in self.uploadRequests.enumerate() {
            if let uploadRequest = uploadRequest {
                uploadRequest.cancel().continueWithBlock({ (task) -> AnyObject! in
                    if let error = task.error {
                        print("cancel() failed: [\(error)]")
                    }
                    if let exception = task.exception {
                        print("cancel() failed: [\(exception)]")
                    }
                    return nil
                })
            }
        }
    }*/
    
    
    
    func elcImagePickerController(picker: ELCImagePickerController!, didFinishPickingMediaWithInfo info: [AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        for (_, imageDictionary) in info.enumerate() {
            if let imageDictionary = imageDictionary as? Dictionary<String, AnyObject> {
                if let mediaType = imageDictionary[UIImagePickerControllerMediaType] as? String {
                    if mediaType == ALAssetTypePhoto {
                        if let image = imageDictionary[UIImagePickerControllerOriginalImage] as? UIImage {
                            let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
                            let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload").URLByAppendingPathComponent(fileName)
                            let filePath = fileURL.path!
                            let imageData = UIImagePNGRepresentation(image)
                            imageData!.writeToFile(filePath, atomically: true)
                            self.fileName = fileName
                            MobileBackendApi.sharedInstance.uploadImageToS3(fileURL, localFileName: fileName, imageView: imageView, progressView: processView, lable: labelUploaded)
           
                        }
                    }
                }
            }
        }
        //self.collectionView.reloadData()
    }
    
    func elcImagePickerControllerDidCancel(picker: ELCImagePickerController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

