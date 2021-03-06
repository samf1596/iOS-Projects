//
//  ViewController.swift
//  Campus Walk
//
//  Created by Samuel Fox on 10/13/18.
//  Copyright © 2018 sof5207. All rights reserved.
//

import UIKit
import MapKit

class CampusBuilding : NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title : String?
    let favorite : Bool?
    init(title:String?, coordinate:CLLocationCoordinate2D, favorite:Bool) {
        self.title = title
        self.coordinate = coordinate
        self.favorite = favorite
    }
}

class FavoriteBuilding : NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title : String?
    let favorite : Bool?
    init(title:String?, coordinate:CLLocationCoordinate2D, favorite:Bool) {
        self.title = title
        self.coordinate = coordinate
        self.favorite = favorite
    }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, PlotBuildingDelegate, OptionsDelegate, SaveImageDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var navBar: UINavigationItem!
    @IBOutlet var directionsButton: UIBarButtonItem!
    @IBOutlet var showStepsButton: UIBarButtonItem!
    
    let mapModel = CampusModel.sharedInstance
    let locationManager = CLLocationManager()
    let userMapLocation = MKUserLocation()
    let kSpanLatitudeDelta = 0.027
    let kSpanLongitudeDelta = 0.027
    let kSpanLatitudeDeltaZoom = 0.002
    let kSpanLongitudeDeltaZoom = 0.002
    let kInitialLatitude = 40.8012
    let kInitialLongitude = -77.859909
    var directionsAlert = UIAlertController()
    var allAnnotations = [MKAnnotation]()
    var allFavorites = [MKAnnotation]()
    var allBuildings = false
    var userLocation = false
    var mapTypeIndex = 0
    var favorites = false
    var namesOfFavorites = [String]()
    var allAnnotationsNames = [String]()
    var fromLocation = String()
    var toLocation = String()
    var currentPaths = [MKOverlay]()
    var steps = [MKRoute.Step]()
    var savedImages = [String:UIImage]()
    var savedDetails = [String:String]()
    @IBOutlet var etaLabel: UILabel!
    
    @IBAction func showSteps(_ sender: Any) {
        
        let stepsTableView = self.storyboard?.instantiateViewController(withIdentifier: "StepsTableView") as! StepsTableViewController
        stepsTableView.configure(steps)
        let nav = UINavigationController(rootViewController: stepsTableView)
        self.present(nav, animated: true, completion: nil)
        
    }
    
    func directionsToLocation(){
        guard toLocation.count > 0 && fromLocation.count > 0 else { return }
        etaLabel.removeFromSuperview()
        mapView.removeOverlays(currentPaths)
        mapView.removeAnnotations(allAnnotations)
        let routeRequest = MKDirections.Request()
        
        if fromLocation == "Current Location"{
            routeRequest.source = MKMapItem.forCurrentLocation()
        }
        else {
            let location = mapModel.buildingLocation(fromLocation)
            var mapItem : MKMapItem {
                let placeMark = MKPlacemark(coordinate: (location?.coordinate)!)
                let item = MKMapItem(placemark: placeMark)
                return item
            }
            routeRequest.source = mapItem
            plot(building: fromLocation, changeRegion: true)
        }
        
        if toLocation == "Current Location"{
            routeRequest.source = MKMapItem.forCurrentLocation()
        }
        else {
            let location = mapModel.buildingLocation(toLocation)
            var mapItem : MKMapItem {
                let placeMark = MKPlacemark(coordinate: (location?.coordinate)!)
                let item = MKMapItem(placemark: placeMark)
                return item
            }
            routeRequest.destination = mapItem
            plot(building: toLocation, changeRegion: false)
        }
        routeRequest.transportType = .walking
        routeRequest.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: routeRequest)
        directions.calculate { (response, error) in
            guard error == nil else {print(error?.localizedDescription as Any); return}
            
            let route = response?.routes.first!
            self.mapView.addOverlay((route?.polyline)!)
            self.currentPaths.append((route?.polyline)!)
            self.etaLabel.text = "ETA: " +
            DateFormatter.localizedString(from: Date(timeIntervalSinceNow: (response?.routes.first!.expectedTravelTime)!), dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)
            self.etaLabel.textColor = self.view.tintColor
            self.navBar.titleView = self.etaLabel
            self.steps = (route?.steps)!
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case is MKPolyline:
            let line = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            line.strokeColor = UIColor.blue
            line.lineWidth = 4.0
            return line
        default:
            assert(false, "UNHANDLED OVERLAY")
        }
    }
    
    @IBAction func removePaths(_ sender: Any) {
        mapView.removeOverlays(currentPaths)
        mapView.removeAnnotations(allAnnotations)
        etaLabel.removeFromSuperview()
    }
    
    @IBAction func directionsAction(_ sender: Any) {
        let alertView = UIAlertController(title: "Directions", message: nil, preferredStyle: .actionSheet)
        alertView.popoverPresentationController?.barButtonItem = directionsButton
        
        let actionFromDirection = UIAlertAction(title: "From", style: .default) { (action) in
            let newAlertView = UIAlertController(title: "Use Current Location", message: nil, preferredStyle: .actionSheet)
            let yes = UIAlertAction(title: "Yes", style: .default) {(action) in
                self.fromLocation = "Current Location"
                let alertView = UIAlertController(title: "Directions", message: nil, preferredStyle: .actionSheet)
                self.alertConfigure(self.fromLocation, self.toLocation, alertView)
                alertView.popoverPresentationController?.barButtonItem = self.directionsButton
                self.present(alertView, animated: true, completion: nil)
            }
            newAlertView.addAction(yes)
            let no = UIAlertAction(title: "No, a Building", style: .default) {(action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "FROM")
            }
            newAlertView.addAction(no)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            newAlertView.addAction(actionCancel)
            
            self.present(newAlertView, animated: true, completion: nil)
        }
        alertView.addAction(actionFromDirection)
        
        let actionToDirection = UIAlertAction(title: "To", style: .default) { (action) in
            let newAlertView = UIAlertController(title: "Use Current Location", message: nil, preferredStyle: .actionSheet)
            let yes = UIAlertAction(title: "Yes", style: .default) {(action) in
                self.toLocation = "Current Location"
                let alertView = UIAlertController(title: "Directions", message: nil, preferredStyle: .actionSheet)
                self.alertConfigure(self.fromLocation, self.toLocation, alertView)
                alertView.popoverPresentationController?.barButtonItem = self.directionsButton
                self.present(alertView, animated: true, completion: nil)
            }
            newAlertView.addAction(yes)
            let no = UIAlertAction(title: "No, a Building", style: .default) {(action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "TO")
            }
            newAlertView.addAction(no)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            newAlertView.addAction(actionCancel)
            
            self.present(newAlertView, animated: true, completion: nil)
        }
        alertView.addAction(actionToDirection)
        
        let actionGoDirection = UIAlertAction(title: "Go", style: .default) {(action) in
            self.directionsToLocation()
        }
        alertView.addAction(actionGoDirection)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertView.addAction(actionCancel)
        directionsAlert = alertView
        self.present(alertView, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let coordinate  = CLLocationCoordinate2D(latitude: kInitialLatitude, longitude: kInitialLongitude)
        let span = MKCoordinateSpan(latitudeDelta: kSpanLatitudeDelta, longitudeDelta: kSpanLongitudeDelta)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        mapView.delegate = self
        locationManager.delegate = self
        
        let trackButton = MKUserTrackingBarButtonItem(mapView: self.mapView)
        navBar.leftBarButtonItem = trackButton
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            mapView.showsUserLocation = false
            userLocation = false
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .followWithHeading
            userLocation = true
        default:
            break
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if userLocation {
            mapView.userTrackingMode = .followWithHeading
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is CampusBuilding:
            return annotationView(forCampusBuilding: annotation as! CampusBuilding)
        case is FavoriteBuilding:
            return annotationView(forFavoriteBuilding: annotation as! FavoriteBuilding)
        default:
            return nil
        }
    }
    
    func annotationView(forCampusBuilding campusBuilding:CampusBuilding) -> MKAnnotationView {
        let identifier = "BuildingPin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: campusBuilding, reuseIdentifier: identifier)
            view.pinTintColor = MKPinAnnotationView.redPinColor()
            view.animatesDrop = true
            view.canShowCallout = true
            let button = UIButton(type: .detailDisclosure)
            button.setTitle("X", for: .normal)
            button.setImage(UIImage(named: "delete"), for: .normal)
            view.rightCalloutAccessoryView = button
            view.leftCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            let name = view.annotation?.title
            if namesOfFavorites.contains(name!!){
                let index = namesOfFavorites.firstIndex(of: name!!)
                namesOfFavorites.remove(at: index!)
                allFavorites.remove(at: index!)
            }
            if allAnnotationsNames.contains(name!!) {
                let index = allAnnotationsNames.firstIndex(of: name!!)
                allAnnotationsNames.remove(at: index!)
                allAnnotations.remove(at: index!)
            }
            mapView.removeAnnotation(view.annotation!)
        }
        if control == view.leftCalloutAccessoryView {
            let detailView = self.storyboard?.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
            detailView.delegate = self
            let buildingName = view.annotation?.title
            let imageName = mapModel.buildingPhotoName(buildingName!!)
            var image = UIImage()
            if imageName!.count > 0 {
                image = UIImage(named: imageName!)!
            }
            else {
                image = UIImage(named: "addPhoto")!
            }
            detailView.configure(image, buildingName!!, savedImages, savedDetails)
            let nav = UINavigationController(rootViewController: detailView)
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func plot(building: String, changeRegion : Bool = true) {
        if allAnnotationsNames.contains(building) {
            return
        }
        let coordinate = mapModel.buildingLocation(building)?.coordinate
        let title = building
        
        let span = MKCoordinateSpan(latitudeDelta: kSpanLatitudeDeltaZoom, longitudeDelta: kSpanLongitudeDeltaZoom)
        
        if changeRegion {
            let region = MKCoordinateRegion(center: coordinate!, span: span)
            self.mapView.setRegion(region, animated: true)
        }
        let campusBuilding = CampusBuilding(title: title, coordinate: coordinate!, favorite: false)
        allAnnotations.append(campusBuilding)
        allAnnotationsNames.append(building)
        self.mapView.addAnnotation(campusBuilding)
    }
    
    func annotationView(forFavoriteBuilding favoriteBuilding:FavoriteBuilding) -> MKAnnotationView {
        let identifier = "BuildingFavoritePin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: favoriteBuilding, reuseIdentifier: identifier)
            view.pinTintColor = MKPinAnnotationView.greenPinColor()
            view.animatesDrop = true
            view.canShowCallout = true
            let button = UIButton(type: .detailDisclosure)
            button.setTitle("X", for: .normal)
            button.setImage(UIImage(named: "delete"), for: .normal)
            view.rightCalloutAccessoryView = button
        }
        
        return view
    }
    
    func plotFavorite(building: String) {
        let coordinate = mapModel.buildingLocation(building)?.coordinate
        let title = building
        
        let campusBuilding = FavoriteBuilding(title: title, coordinate: coordinate!, favorite: true)
        allFavorites.append(campusBuilding)
        self.mapView.addAnnotation(campusBuilding)
    }

    func userLocation(_ toggle : Bool){
        userLocation = toggle
        if CLLocationManager.locationServicesEnabled() && toggle {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                mapView.showsUserLocation = true
                mapView.userTrackingMode = .followWithHeading
                locationManager.startUpdatingHeading()
            default:
                break
                
            }
        }
        else {
            mapView.showsUserLocation = false
        }
    }
    
    func showAllBuildings(_ toggle : Bool){
        allBuildings = toggle
        if toggle == true {
            for i in 0..<mapModel.numberOfBuildings(){
                plot(building: mapModel.nameOfBuilding(i), changeRegion: false)
            }
        }
        else {
            mapView.removeAnnotations(allAnnotations)
        }
    }
    
    func mapType(_ type : Int){
        mapTypeIndex = type
        switch type{
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            return
        }
    }
    
    func showFavorites(_ toggle: Bool) {
        favorites = toggle
        if toggle == true {
            for i in namesOfFavorites{
                plotFavorite(building: i)
            }
        }
        else {
            mapView.removeAnnotations(allFavorites)
        }
    }
    
    func favoriteBuilding(name: String) {
        
        if namesOfFavorites.contains(name) {
            let index = namesOfFavorites.firstIndex(of: name)
            namesOfFavorites.remove(at: index!)
            mapView.removeAnnotation(allFavorites[index!])
            allFavorites.remove(at: index!)
            return
        }
        let coordinate = mapModel.buildingLocation(name)?.coordinate
        let title = name
        namesOfFavorites.append(name)
        let favoriteBuilding = FavoriteBuilding(title: title, coordinate: coordinate!, favorite : true)
        allFavorites.append(favoriteBuilding)
    }
    
    func alertConfigure(_ from : String, _ to : String, _ alertView : UIAlertController) {
        if from.count>1 {
            let fromLocationAction = UIAlertAction(title: "From \(from)", style: .default) { (action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "FROM")
            }
            alertView.addAction(fromLocationAction)
        }
        else {
            let fromLocationAction = UIAlertAction(title: "From", style: .default) { (action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "FROM")
            }
            alertView.addAction(fromLocationAction)
        }
        if to.count>1 {
            let toLocationAction = UIAlertAction(title: "To \(to)", style: .default) { (action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "TO")
            }
            alertView.addAction(toLocationAction)
        }
        else {
            let toLocationAction = UIAlertAction(title: "To", style: .default) { (action) in
                self.performSegue(withIdentifier: "BuildingList", sender: "TO")
            }
            alertView.addAction(toLocationAction)
        }
        let go = UIAlertAction(title: "Go", style: .default) {(action) in
            self.directionsToLocation()
        }
        alertView.addAction(go)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
    }
    
    func directionsFrom(name: String) {
        fromLocation = name
        let alertView = UIAlertController(title: "Directions", message: nil, preferredStyle: .actionSheet)
        alertConfigure(fromLocation, toLocation, alertView)
        alertView.popoverPresentationController?.barButtonItem = directionsButton
        self.present(alertView, animated: true, completion: nil)
        return
    }
    func directionsTo(name: String) {
        toLocation = name
        let alertView = UIAlertController(title: "Directions", message: nil, preferredStyle: .actionSheet)
        alertConfigure(fromLocation, toLocation, alertView)
        alertView.popoverPresentationController?.barButtonItem = directionsButton
        self.present(alertView, animated: true, completion: nil)
        return
    }
    func save(_ building: String, _ image: UIImage) {
        savedImages[building] = image
    }
    func saveDetails(_ building: String, _ details: String) {
        savedDetails[building] = details
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "BuildingList":
            let navController = segue.destination as! UINavigationController
            let buildingListViewController = navController.topViewController as! TableViewController
            buildingListViewController.delegate = self
            buildingListViewController.configure(namesOfFavorites, sender)
        case "OptionsSegue":
            let navController = segue.destination as! UINavigationController
            let optionsController = navController.topViewController as! OptionsViewController
            optionsController.delegate = self
            optionsController.configure(userLocation: userLocation, allBuildings: allBuildings, mapType: mapTypeIndex, favorites: favorites)
        default:
            assert(false, "Unhandled Segue")
        }
    }

}

