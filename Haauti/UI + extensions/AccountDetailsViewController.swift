//
//  AccountDetailsViewController.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 26/04/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import MapKit

class MapPin : NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    dynamic var title: String?
    dynamic var subtitle: String?
    var draggable = true
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

class AccountDetailsViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet weak var field : NSTextField!
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var karmaIndicator : NSTextField!
    @IBOutlet weak var followUserCheckbox : NSButton!
    
    weak var lastPinnedLocation : MapPin! {
        didSet {
            self.account?.location = lastPinnedLocation.coordinate
        }
    }
    
    weak var account : JodelAccount?
    
    @objc func docHasArrived(notif: NSNotification) {
        account = (notif.object as! JodelAccount)
        account?.register(accountDelegate: self)
        field.stringValue = account!.device_uid
        
        self.dropPin(at: self.account!.location)
        self.mapView.centerCoordinate = self.account!.location
        
        followUserCheckbox.state = account!.settings.followUserLocation ? .on : .off
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        NotificationCenter.default.addObserver(self, selector: #selector(self.docHasArrived), name: Notification.Name("DocumentHasArrived"), object: nil)
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        let gp = NSPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        gp.minimumPressDuration = 0.3
        self.mapView.addGestureRecognizer(gp)
    }
    
    @IBAction func followUserSwitched(_ sender: NSButton) {
        if let account = account {
            account.settings.followUserLocation = (followUserCheckbox.state == .on)
            dropPin(at: mapView.userLocation.coordinate)
            updatePin()
        }
        else {
            followUserCheckbox.state = (followUserCheckbox.state == .on) ? .off : .on //reverse user change to mirror fact that nothing was setted
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: NSGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            return
        }
        
        let touchPoint = gestureRecognizer.location(in: self.mapView)
        let destination = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        
        if (gestureRecognizer.state == .changed) {
            self.lastPinnedLocation.coordinate = destination
            return
        }
        self.dropPin(at: destination)
    }
    
    func updatePin() {
        guard let l = lastPinnedLocation else { return }
        
        let pin = MapPin(coordinate: l.coordinate, title: l.title, subtitle: l.subtitle)
        self.mapView.addAnnotation(pin)
        mapView.removeAnnotation(l)
        self.lastPinnedLocation = pin
    }
    
    func dropPin(at: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        let pin = MapPin(coordinate: at, title: title, subtitle: subtitle)
        
        if let last = self.lastPinnedLocation {
            mapView.removeAnnotation(last)
        }
        
        self.mapView.addAnnotation(pin)
        self.lastPinnedLocation = pin
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        if let annotation = annotation as? MapPin {
            let ident = annotation.title ?? nil
            if let ident = ident {
                view = mapView.dequeueReusableAnnotationView(withIdentifier:ident)
            }
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ident)
            }
            view.isDraggable = annotation.draggable
            if let view = view as? MKPinAnnotationView {
                view.pinTintColor = NSColor.gray
                
                if let account = account {
                    if !account.settings.followUserLocation {
                        view.pinTintColor = NSColor.red
                    }
                }
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.centerCoordinate = userLocation.coordinate
    }
}

extension AccountDetailsViewController : JodelAccountDelegate {
    func update(karma: Int) {
        let string = "Karma: \(karma)"
        self.karmaIndicator.stringValue = string
        if (karma >= 0) {
            self.karmaIndicator.textColor = JodelAPISettings.colors.green
        } else {
            self.karmaIndicator.textColor = JodelAPISettings.colors.red
        }
    }
    
    func errorOccurred(_: JodelError) {
        return
    }
}
