//
//  MobileBackendApi.swift
//  MobileBackendIOS
//

import Foundation


class MobileBackendApi  {
    
    static let sharedInstance = MobileBackendApi()
    let awsCognitoCredentialsProvider: AWSCognitoCredentialsProvider
    var cognitoId:String?
    
    
    init() {
        //Initialize the identity provider
        self.awsCognitoCredentialsProvider = AWSCognitoCredentialsProvider.credentialsWithRegionType(CognitoRegionType, accountId: AWSAccountId, identityPoolId: CognitoIdentityPoolId, unauthRoleArn: CognitoUnauthenticatedRoleArn, authRoleArn: CognitoAuthenticatedRoleArn)
    }
    
    func requestCognitoIdentity() {
        awsCognitoCredentialsProvider.getIdentityId().continueWithBlock() { (task) -> AnyObject! in
            if let error = task.error {
                print("Error Requesting Unauthenticated user identity: \(error.userInfo)")
                self.cognitoId = nil
            } else {
                self.cognitoId = self.awsCognitoCredentialsProvider.identityId
            }
            return nil
        }
    }
    
    func configureS3TransferManager() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        AWSS3TransferManager.registerS3TransferManagerWithConfiguration(configuration, forKey: "USEast1AWSTransferManagerClient")
    }
    
    func configureNoteApi() {
        let configuration = AWSServiceConfiguration(region: DefaultServiceRegionType, credentialsProvider: self.awsCognitoCredentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        APINotesApiClient.registerClientWithConfiguration(configuration, forKey: "USEast1NoteAPIManagerClient", withUrl: APIEndpointUrl)
        APINotesApiClient(forKey: "USEast1NoteAPIManagerClient").APIKey = APIGatewayKey
    }
    
    func searchNotes(searchTerm: String) -> AWSTask{

        let noteApiClient = APINotesApiClient(forKey: "USEast1NoteAPIManagerClient")

        return noteApiClient.notesGet(searchTerm).continueWithBlock { (task) -> AnyObject! in
            return task
            
        }

    }
    
    func postNote(headline: String, text: String, s3key: String, viewController: UIViewController) {
        let noteRequest = APICreateNoteRequest()
        noteRequest.headline = headline
        noteRequest.text = text
        noteRequest.s3key = s3key
        noteRequest.noteId = NSUUID().UUIDString
        
        let noteApiClient = APINotesApiClient(forKey: "USEast1NoteAPIManagerClient")
        noteApiClient.notesPost(noteRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                print("Failed creating note: [\(error)]")
            }
            if let exception = task.exception {
                print("Failed creating note: [\(exception)]")
            }
            if let noteResponse = task.result as? APICreateNoteResponse {
                if((noteResponse.success) != nil) {
                    print("Saved note successfully")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let alertController = UIAlertController(title: "", message:
                            "保存成功!", preferredStyle: UIAlertControllerStyle.Alert)
                        alertController.addAction(UIAlertAction(title: "知道了。。。", style: UIAlertActionStyle.Default,handler: nil))
                        
                        viewController.presentViewController(alertController, animated: true, completion: nil)
                    })
                }else {
                    print("Unable to save note due to unknown error")
                }
            }
            return task
        }
    }
    
    func uploadImageToS3(localFileURL: NSURL, localFileName: String, imageView: UIImageView, progressView: UIProgressView, lable: UILabel ){
        let uploadRequest:AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = "image/png"
        uploadRequest.body = localFileURL
        uploadRequest.key = localFileName
        
        let s3TransferManager = AWSS3TransferManager.S3TransferManagerForKey("USEast1AWSTransferManagerClient")
        
        s3TransferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch (errorCode){
                        case .Cancelled, .Paused:
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    //uiView.reloadData()
                            })
                                break;
                        default:
                            print("upload() failed: [\(error)]")
                        }
                    }
                    
                } else {
                    print("upload() failed: [\(error)]")
                }
            }
            
            if let exception = task.exception {
                print("upload() failed: [\(exception)]")
            }
            
            if task.result != nil {
                print("Uploaded local file to S3: [\(localFileName)]")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    lable.hidden = false
                })
            }
            return nil
        }
        
        
        
        if let data = NSData(contentsOfURL: localFileURL) {
            imageView.image = UIImage(data: data)
        }
        

        uploadRequest.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if totalBytesExpectedToSend > 0 {
                    progressView.progress = Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
                }
            })
        }
    }
    
    func downloadImage(fileName: String, imageURL: UIImageView){
        let url = NSURL(string: fileName)
        imageURL.image = nil
        print("Started downloading \"\(url!.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url!) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print("Finished downloading \"\(url!.URLByDeletingPathExtension!.lastPathComponent!)\".")
                imageURL.image = UIImage(data: data)
            }
        }
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }

}

