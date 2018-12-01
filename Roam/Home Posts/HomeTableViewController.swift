//
//  HomeTableViewController.swift
//  
//
//  Created by Samuel Fox on 11/20/18.
//

import UIKit
import Firebase

class HomeTableViewController: UITableViewController, UIGestureRecognizerDelegate {

    fileprivate var ref : DatabaseReference!
    fileprivate var storageRef : StorageReference!
    
    @IBOutlet var homeTableView: UITableView!
    
    let cachedImage = CachedImages()
    var tableViewSwipeUpGesture = UISwipeGestureRecognizer()
    var tableViewSwipeDownGesture = UISwipeGestureRecognizer()
    var posts = [Post]()
    var cachedPosts = [Post]()
    var hideStatusBar = false
    
    let postsModel = PostsModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(GlobalUsersTableViewController.didSwipe(_:)))
        swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        swipeUp.delegate = self
        self.homeTableView.addGestureRecognizer(swipeUp)
        self.tableViewSwipeUpGesture = swipeUp
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(GlobalUsersTableViewController.didSwipe(_:)))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        swipeDown.delegate = self
        self.homeTableView.addGestureRecognizer(swipeDown)
        self.tableViewSwipeDownGesture = swipeDown
        
        navigationController?.hidesBarsOnSwipe = true
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
    }

    @objc func didSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizer.Direction.down:
            hideStatusBar = false
        case UISwipeGestureRecognizer.Direction.up:
            hideStatusBar = true
        default:
            break
        }
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //Identify gesture recognizer and return true else false.
        return gestureRecognizer.isEqual(self.tableViewSwipeUpGesture) || gestureRecognizer.isEqual(self.tableViewSwipeDownGesture) ? true : false
    }
    
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Let's GOOOOOO!!!!!")
        
        postsModel.findFollowingPosts()
        postsModel.refreshContent(for: self.tableView, with: self.refreshControl)
        
        /*
        var following = [String]()
        //var account : NewUser?
        
        if Auth.auth().currentUser != nil {
            ref.child(FirebaseFields.Users.rawValue).child(Auth.auth().currentUser!.uid).child("following").observe(.value) { (snapshot) in
                for user in snapshot.children {
                    let temp = user as! DataSnapshot
                    following.append(temp.key)
                }
            }
            
            ref.child(FirebaseFields.Posts.rawValue).observe(.value) { (snapshot) in
                var posts = [Post]()
                for postSnapshot in snapshot.children {
                    let post = Post(snapshot: postSnapshot as! DataSnapshot)
                    if following.contains(post.username) {
                        posts.append(post)
                    }
                }
                self.posts = posts
                let block = {
                    self.cachedPosts = self.posts.reversed()
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
                DispatchQueue.main.async(execute: block)
            }
        }
         */
        super.viewWillAppear(animated)
    }
    

    
    
    @IBAction func refreshContent(_ sender: UIRefreshControl) {
        postsModel.findFollowingPosts()
        postsModel.refreshContent(for: self.tableView, with: self.refreshControl)
        
        /*
        let block = {
            self.cachedPosts = self.posts.reversed()
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        DispatchQueue.main.async(execute: block)
        */
    }
    
    /*
    func downloadImage(_ indexPath: IndexPath, _ imageURL: String) {
        let storage = storageRef.storage.reference(forURL: cachedPosts[indexPath.section].imagePath)
        storage.getData(maxSize: 2*1024*1024) { (data, error) in
            if error == nil {
                //self.cachedPosts[indexPath.section].cachedImage = UIImage(data: data!)
                let image = UIImage(data: data!)
                self.cachedImage.cacheImage(imageURL, image!)
            }
            else {
                print("Error:\(error ?? "" as! Error)")
            }
        }
    }
    */
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return postsModel.cachedFollowingPostsCount
        //return self.cachedPosts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > 0 {
            return 2.5
        }
        else {
            return 0.0
        }
    }
    
    /*
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: 2.5))
        view.backgroundColor = self.view.tintColor
        return view
    }
    */
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        
        let imagePath = postsModel.imagePathForFollowingPost(indexPath.section)
        postsModel.downloadFollowingImage(indexPath, imagePath)
        
        //downloadImage(indexPath, cachedPosts[indexPath.section].imagePath)
        cell.globalPostImageView.image = postsModel.getCachedImage(imagePath)
        cell.post = postsModel.postForFollowingSection(indexPath.section)
        cell.globalPostExperienceDetails.tag = indexPath.section
        cell.unfollowButton.layer.cornerRadius = 10.0
        return cell
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}