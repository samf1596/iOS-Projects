//
//  ParkCollectionViewController.swift
//  Park Explorer
//
//  Created by Samuel Fox on 9/30/18.
//  Copyright © 2018 Samuel Fox. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class ParkCollectionViewController: UICollectionViewController, ZoomDelegate {

    @IBOutlet var parkCollectionView: UICollectionView!
    let parkModel = Model()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return parkModel.lengthOfParks()
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return parkModel.parkInfoLength(section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParkCollectionCell", for: indexPath) as! ParkCollectionViewCell
    
        // Configure the cell
        let parkName = parkModel.park(indexPath.section)
        let parkImageName = parkName+"0\(indexPath.row+1)"
        let parkImage = UIImage(named: parkImageName)
        cell.parkImageView.image = parkImage
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! ParkCollectionReusableView
            let parkName = parkModel.park(indexPath.section)
            headerView.parkCollectionHeader.text = parkName
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        parkCollectionView.reloadData()
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ZoomSegue":
            let zoomController = segue.destination as! ParkZoomViewController
            let index = parkCollectionView.indexPathsForSelectedItems!
            print(index)
            let park = parkModel.park(index[0][0])
            let image = UIImage(named: park+"0\(index[0][1]+1)")
            zoomController.delegate = self
            zoomController.configure(image!)
        default:
            assert(false, "Unhandled Segue")
        }
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }

}