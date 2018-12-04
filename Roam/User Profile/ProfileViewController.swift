//
//  ProfileViewController.swift
//  Roam
//
//  Created by Samuel Fox on 11/5/18.
//  Copyright © 2018 sof5207. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MainViewDelegate {
    
    fileprivate var ref : DatabaseReference!
    fileprivate var storageRef : StorageReference!
    
    @objc func onNotification(notification:Notification) {
        if notification.name == Notification.Name("settingsChanged") {
            if notification.userInfo!["theme"] as! String == Themes.Dark.rawValue {
                print("DARK THEME")
                self.view.tintColor = UIColor.darkGray
                self.view.backgroundColor = UIColor.darkGray
            }
            else {
                print("LIGHT THEME")
                self.view.tintColor = UIColor.white
                self.view.backgroundColor = UIColor.white
            }
        }
    }
    
    @IBOutlet weak var profileCollectionView: UICollectionView!
    
    var collectionToShow = "UsersPosts"
    var pageTitle = String()
    
    let postModel = PostsModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotification(notification:)), name: SettingsViewController.settingsChanged, object: nil)
        
        profileCollectionView.dataSource = self
        profileCollectionView.delegate = self
        
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
    }
    
    func toggleCollectionViewType(show collection: String) {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
        self.collectionToShow = collection
        profileCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        postModel.findUsersPosts()
        postModel.findBookmarkedPosts()
        self.profileCollectionView.reloadData()
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionToShow == "UsersPosts" {
            return postModel.cachedUsersPostsCount
        }
        else {
            return postModel.cachedBookmarkedPostsCount
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as! ProfileCollectionViewCell
        
        if collectionToShow == "BookmarkedPosts"{
            let imagePath = postModel.imagePathForBookmarkedPost(indexPath.row)
            let post = postModel.postForBookmarkedSection(indexPath.row)
            
            postModel.downloadBookmarkedImage(indexPath.row, imagePath, post.postID)
            cell.postImageView.image = postModel.getCachedImage(post.postID)
        }
        else {
            let imagePath = postModel.imagePathForUsersPost(indexPath.row)
            let post = postModel.postForUsersSection(indexPath.row)
            
            postModel.downloadUsersPostImage(indexPath.row, imagePath, post.postID)
            cell.postImageView.image = postModel.getCachedImage(post.postID)
        }
        return cell
    }
    
}

