//
//  ViewController.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController
{
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = MKMapType.Satellite
            mapView.delegate = self
        }
    }
    
    var gpxURL: NSURL? {
        didSet {
            self.mapView.removeAnnotations(mapView.annotations) // first clean up annotations
            
            // Analyze the GPX file and Add waypoints to map view
            if let url = gpxURL {
                GPX.parse(url, completionHandler: { (gpx: GPX?) -> Void in
                    if let gpx = gpx {
                        self.mapView.addAnnotations(gpx.waypoints)
                        self.mapView.showAnnotations(gpx.waypoints, animated: true)
                    }
                })
            }
        }
    }
    
    var gpxFileObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        handleReceivedFile()
        
        gpxURL = NSURL(string: Constants.TestURLString)     // for testing
    }

    func handleReceivedFile()
    {
        let center = NSNotificationCenter.defaultCenter()
        gpxFileObserver = center.addObserverForName(Constants.OpenFileNotification, object: UIApplication.sharedApplication().delegate, queue: NSOperationQueue.mainQueue(), usingBlock: { (noti: NSNotification) -> Void in
            if let url = noti.userInfo?[Constants.OpenFileKey] as? NSURL {
                self.gpxURL = url
            }
        })
    }

    deinit {
        if gpxFileObserver != nil {
            NSNotificationCenter.defaultCenter().removeObserver(gpxFileObserver!)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == Constants.ShowImageSegue
        {
            let imc = segue.destinationViewController as? ImageViewController
            imc?.imageURL = (sender?.annotation as? GPX.Waypoint)?.imageURL
        }
        else if segue.identifier == Constants.EditWaypointPopoverSegue {
            if let waypoint = sender?.annotation as? EditableWaypoint
            {
                if let ewvc = segue.destinationViewController.contentVC as? EditWaypointViewController
                {
                    if let ppc = ewvc.popoverPresentationController
                    {
                        let viewPoint = mapView.convertCoordinate(waypoint.coordinate, toPointToView: mapView)
                        ppc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForPoint(viewPoint)
                        
                        let minimumSize = ewvc.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                        // The preferredContentSize is used for any container laying out a child view controller.
                        ewvc.preferredContentSize = CGSize(width: Constants.EditWaypointPopoverWidth, height: minimumSize.height)
                        ppc.delegate = self
                    }
                    ewvc.waypointToEdit = waypoint
                }
            }//waypoint
        }
    }
    
    // Long press to add a waypoint
    @IBAction func addPinAnnotation(sender: UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.Began
        {
            let point = sender.locationInView(mapView)
            let mapPos = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            let waypoint = EditableWaypoint(lati: mapPos.latitude, lgti: mapPos.longitude)
            waypoint.name = "Dropped"
            
            mapView.addAnnotation(waypoint) // Add the specified annotation to the map view
        }
    }
    
}

extension UIViewController {
    // return the correct view controller even it maybe be embeded
    var contentVC: UIViewController {
        if let navi = self as? UINavigationController {
            return navi.visibleViewController!
        } else {
            return self
        }
    }
}

extension MKAnnotationView
{
    func popoverSourceRectForPoint(point: CGPoint) -> CGRect
    {
        var popoverSourceRectCenter = point
        // centerOffset -- By default, the center point of an annotation view is placed at the coordinate point of the associated annotation.
        // calloutOffset -- When this property is set to (0, 0), the anchor point of the callout bubble is placed on the top-center point of the annotation view’s frame.
        popoverSourceRectCenter.x -= frame.width/2 - centerOffset.x - calloutOffset.x
        popoverSourceRectCenter.y -= frame.height/2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectCenter, size: frame.size)
    }
}

extension ViewController: MKMapViewDelegate
{
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        var anno = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.WaypointAnnotationID)
        
        if anno == nil {
            anno = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.WaypointAnnotationID)
            anno?.canShowCallout = true
        }
        else { // update annotation
            anno?.annotation = annotation
        }
        
        anno?.draggable = annotation is EditableWaypoint    // Manually added annotation can be dragged
        
        anno?.leftCalloutAccessoryView = nil
        anno?.rightCalloutAccessoryView = nil
        
        if let waypoint = annotation as? GPX.Waypoint
        {
            if waypoint.thumbnailURL != nil {
                anno?.leftCalloutAccessoryView = UIButton(frame: Constants.CalloutImageFrame)
            }
            
            if annotation is EditableWaypoint {
                anno?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            }
        }
        
        return anno
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if let waypoint = view.annotation as? GPX.Waypoint
        {
            if let url = waypoint.thumbnailURL
            {
                if view.leftCalloutAccessoryView == nil {
                    // a thumnnail must have been added since the annotation view was created
                    view.leftCalloutAccessoryView = UIButton(frame: Constants.CalloutImageFrame)
                }
                
                // lazy download image
                if let imageButton = view.leftCalloutAccessoryView as? UIButton {
                    if let imageData = NSData(contentsOfURL: url) {
                        if let image = UIImage(data: imageData) {
                            imageButton.setImage(image, forState: .Normal)
                        }
                    }
                }
            }//url
        }
    }
    
    // Tells the delegate that the user tapped one of the annotation view’s accessory buttons.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        if view.annotation is EditableWaypoint {
            // Deselect the specified annotation and hides its callout
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            performSegueWithIdentifier(Constants.EditWaypointPopoverSegue, sender: view)
        }
        else if view.annotation is GPX.Waypoint { // Segue to image view controller
            performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
        }
    }
    
}

extension ViewController: UIPopoverPresentationControllerDelegate
{
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.OverFullScreen
    }
    
    // return navi when on iPhone
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController?
    {
        let navi = UINavigationController(rootViewController: controller.presentedViewController)
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
        visualEffectView.frame = navi.view.bounds
        
        navi.view.insertSubview(visualEffectView, atIndex: 0)   // back-most subview
        return navi
    }
}
