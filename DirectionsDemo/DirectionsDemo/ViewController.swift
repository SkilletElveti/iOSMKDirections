//
//  ViewController.swift
//  DirectionsDemo
//
//  Created by Shubham Vinod Kamdi on 09/10/19.
//  Copyright © 2019 Shubham Vinod Kamdi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    var locationManager: CLLocationManager!
    var anno : MKPointAnnotation!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var sourceCity: UITextField!
    @IBOutlet weak var destinationCity: UITextField!
    var reverse: ReverseGeoCode!
    var sourceCordinate: CLLocationCoordinate2D!
    var destinationCordinate: CLLocationCoordinate2D!
    @IBOutlet weak var pickUpBtn: UIButton!
    @IBOutlet weak var dropBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reverse = ReverseGeoCode()
        map.delegate = self
        self.sourceCity.layer.borderWidth = 1
        self.destinationCity.layer.borderWidth = 1
        self.sourceCity.layer.cornerRadius = 15
        self.destinationCity.layer.cornerRadius = 15
        self.sourceCity.layer.borderColor = UIColor.black.cgColor
        self.destinationCity.layer.borderColor = UIColor.black.cgColor
        self.destinationCity.layer.shadowRadius = 1
        self.destinationCity.layer.shadowColor = UIColor.cyan.cgColor
        self.sourceCity.layer.shadowRadius = 1
        self.sourceCity.layer.shadowColor = UIColor.cyan.cgColor
        locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
        }
        //updateMap()
        map.delegate = self
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.showsUserLocation = true
        
        print(locationManager.location?.coordinate.latitude)
        print(locationManager.location?.coordinate.longitude)
        if let coor = map.userLocation.location?.coordinate{
            map.setCenter(coor, animated: true)
            print("USER \(coor.latitude) \(coor.longitude)")
        }
        
    }
    
    var count: Int = 0
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        if count == 0{
            renderer.strokeColor = UIColor.blue
            count += 1
            renderer.lineWidth = 6
        }else if count <= self.mapRouteNumbers - 1{
            renderer.strokeColor = UIColor.gray
            renderer.lineWidth = 4
            count += 1
           // renderer.lineWidth = 0.2
        }
        
        return renderer
    
    }
    
    var isMapReadyToUpdate: Bool = false
    
    @IBAction func routesAction(){
        if !(sourceCity.text!.isEmpty) && !(destinationCity.text!.isEmpty){
            reverse.getLocation(forPlaceCalled: sourceCity.text!, completion: {
                location in
                self.sourceCordinate =  CLLocationCoordinate2DMake(location!.coordinate.latitude, location!.coordinate.longitude)
                print()
                self.reverse.getLocation(forPlaceCalled: self.destinationCity.text!, completion: {
                    location in
                    self.destinationCordinate = CLLocationCoordinate2DMake( location!.coordinate.latitude, location!.coordinate.longitude)
                    self.isMapReadyToUpdate = true
                    self.updateMap()
                })
             })
        }
    }
    
    var mapRouteNumbers:  Int!
    
    func updateMap(){
        
        
        if isMapReadyToUpdate{
            
           
            
            
            locationManager.requestWhenInUseAuthorization()
            
           
            
            let source = MKPlacemark(coordinate: self.sourceCordinate)
            let destination = MKPlacemark(coordinate: self.destinationCordinate)
            
            let sourceItem = MKMapItem(placemark: source)
            let destinationItem = MKMapItem(placemark: destination)
            
            let directionRequest = MKDirections.Request()
            
            directionRequest.source = sourceItem
            directionRequest.destination = destinationItem
            directionRequest.transportType = .automobile
            directionRequest.requestsAlternateRoutes = true
            
            for overlays in map.overlays{
                if overlays.isKind(of: MKPolyline.self){
                    map.removeOverlay(overlays)
                }
            }
            
            let direction = MKDirections(request: directionRequest)
            
            direction.calculate(completionHandler: {
                response, error in
                
                if error == nil{
                    print(response?.routes.count)
                    self.mapRouteNumbers = response?.routes.count
                    self.count = 0
                    for route in response!.routes{
                        print(route)
                        self.map.addOverlay(route.polyline)
                        self.map.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                        let middlePoint = route.polyline.points()
                        let mid: MKMapPoint = middlePoint[route.polyline.pointCount / 2]
                        //self.createAndAddAnnotationForCoordinate(coordinate: route.polyline.coordinate)
                    }
                    
                }
                
                
            })
            self.isMapReadyToUpdate = false
        }else{
            updateMap()
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let anno = view.annotation else {
            return
        }
    
        print(anno.isKind(of: MKOverlay.self))
    }
//    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
//        renderers.
//    }
    func createAndAddAnnotationForCoordinate(coordinate:CLLocationCoordinate2D) {
        let location = coordinate
        let span = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        let region = MKCoordinateRegion(center: location, span: span)
        map.setRegion(region, animated: true)
        anno = MKPointAnnotation()
        anno.coordinate = location
        anno.title = "Route\(self.count)"
        //anno.subtitle = "London"
        map.addAnnotation(anno)
        
    }
    var pickUpLocation: CLLocationCoordinate2D!
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        pickUpLocation = CLLocationCoordinate2DMake(mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude)
        print("Latitude \(latitude)")
        print("Longitude \(longitude)")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let userLocation:CLLocation = locations[0] as CLLocation
//        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
//        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
//        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude);
//        myAnnotation.title = "Current location"
//        map.addAnnotation(myAnnotation)

    }
    
    var pickUpSelected: Bool = false
    var dropIsSelected: Bool = false
    
    @IBAction func pickUpLocation(_ sender: UIButton!){
        switch sender {
        
        case pickUpBtn:
            if !pickUpSelected{
                
                sourceCordinate = self.pickUpLocation
                pickUpSelected = true
                
                if dropIsSelected{
                    isMapReadyToUpdate = true
                    updateMap()
                    pickUpSelected = false
                    dropIsSelected = false
                
                }
                
            }
            
            break
        
        case dropBtn:
            if !dropIsSelected{
                
                destinationCordinate = self.pickUpLocation
                dropIsSelected = true
                
                if pickUpSelected{
                    isMapReadyToUpdate = true
                    updateMap()
                    pickUpSelected = false
                    dropIsSelected = false
 
                }
            
            }
            break
            
        default:
            print("INVALID I/O")
        }
    }
}

class CustomAnnotation: NSObject, MKAnnotation{
    
    var coordinate: CLLocationCoordinate2D
    var title: String!
    
    init(coordinate: CLLocationCoordinate2D,title: String! ){
        self.coordinate = coordinate
        self.title = title
    }
    
}
