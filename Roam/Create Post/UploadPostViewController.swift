//
//  UploadPostViewController.swift
//  
//
//  Created by Samuel Fox on 11/3/18.
//

import UIKit
import Firebase
import Photos

class UploadPostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, TravelDelegate, ExperiencesDelegate, UITextViewDelegate {

    fileprivate var databaseRef : DatabaseReference!
    fileprivate var storageRef : StorageReference!
    fileprivate var uploadStorageTask: StorageUploadTask!
    fileprivate var imageStoragePath = ""
    
    var imagePicker = UIImagePickerController()
    var imageToUpload = UIImage(named: "addPhoto")
    var travels = [""]
    var experiences = [""]
    var previousHeight : CGFloat = 25.0
    var kKeyboardSize : CGFloat = 0.0
    var keyboardVisible = false
    
    fileprivate var showNetworkActivityIndicator = false {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = showNetworkActivityIndicator
        }
    }
    
    @IBOutlet var uploadImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.delegate = self
        descriptionTextView.returnKeyType = .done
        
        self.imagePicker.delegate = self
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
        
        let addImageGesture = UITapGestureRecognizer(target: self, action: #selector(UploadPostViewController.selectImage(_:)))
        addImageGesture.numberOfTapsRequired = 1
        uploadImageView.addGestureRecognizer(addImageGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
            
        case .authorized: print("Access is granted by user")
            
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                print("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {print("success")
                    
                } })
        case .restricted:
            print("User do not have access to photo album.")
                
        case .denied:
            print("User has denied the permission.") }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name:
            UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification:Notification) {
        if !keyboardVisible && ( self.view.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClass.regular ) {
            let userInfo = notification.userInfo!
            let keyboardSize = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
            if self.view.frame.origin.y == 0{
                kKeyboardSize = keyboardSize!.height
                self.view.frame.origin.y -= keyboardSize!.height
            }
        }
        
        keyboardVisible = true
    }
    
    @objc
    func keyboardWillHide(notification:Notification) {
        if keyboardVisible && ( self.view.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClass.regular ) {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y = 0
            }
        }
        keyboardVisible = false
    }
    
    @objc func selectImage(_ sender: UITapGestureRecognizer) {
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            uploadImageView.alpha = 1.0
            imageToUpload = image
            uploadImageView.image = image
        }
        dismiss(animated: true, completion:nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
    }
    
    @IBAction func submitPost(_ sender: Any) {
        
        let image = imageToUpload!.jpegData(compressionQuality: 0.25)
        let imagePath = "Samf1596"+"/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        showNetworkActivityIndicator = true
        
        let storage = storageRef.child("IMAGES/"+imagePath)
        
        storage.putData(image!).observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    print("File doesn't exist")
                    break
                case .unauthorized:
                    print("User doesn't have permission to access file")
                    break
                case .unknown:
                    print("Unknown Error")
                    break
                default:
                    print("Unhandled Error")
                    break
                }
            }
        }
        
        storage.putData(image!).observe(.success) { (snapshot) in
            // When the image has successfully uploaded, we get it's download URL
            storage.downloadURL(completion: { (url, error) in
                if (error == nil) {
                    if let downloadUrl = url {
                        // Make you download string
                        let downloadURL = downloadUrl.absoluteString
                        self.uploadSuccess(downloadURL)
                        self.showNetworkActivityIndicator = false
                        self.uploadImageView.image = UIImage(named: "addPhoto")
                        self.uploadImageView.alpha = 0.5
                    }
                } else {
                    print("Error:\(String(describing: error?.localizedDescription))")
                }
            })

        }
        
    }
    
    func uploadSuccess(_ imagePath : String) {
        // TODO: Create post with correct experience description.
        var account : NewUser?
        databaseRef.child(FirebaseFields.Accounts.rawValue).child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
        account = NewUser(snapshot: snapshot)
        
            let post = Post(addedByUser: (account?.firstname)!, username: (account?.username)!, description: self.descriptionTextView.text, imagePath: imagePath, experiences: self.experiences, travels: self.travels, isPublic: true)
        
        self.databaseRef.child(FirebaseFields.Posts.rawValue).child(post.username + "\(Int(Date.timeIntervalSinceReferenceDate * 1000))").setValue(post.toObject())
        }
    }
    
    func saveTravels(_ travels: [String]) {
        self.travels = travels
        if self.travels.count < 1 {
            self.travels = [""]
        }
    }
    
    func saveExperiences(_ experiences: [String]) {
        self.experiences = experiences
        if self.experiences.count < 1 {
            self.experiences = [""]
        }
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         switch segue.identifier {
         case "AddExperiences":
             let navController = segue.destination as! UINavigationController
             let experiencesController = navController.topViewController as! ExperiencesTableViewController
             experiencesController.delegate = self
         case "AddTravel":
             let navController = segue.destination as! UINavigationController
             let travelController = navController.topViewController as! FlightsStaysTableViewController
             travelController.delegate = self
         default:
            assert(false, "Unhandled Segue")
         }
     }

}
