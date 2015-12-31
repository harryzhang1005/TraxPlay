//
//  MKGPX.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import MapKit

// Convert waypoint to annotation
extension GPX.Waypoint: MKAnnotation
{
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String? { return name }        // must have
    var subtitle: String? { return info }
    
    // MARK: - Links to Images URL
    var thumbnailURL: NSURL? { return getImageURLwithType("thumbnail") }
    var imageURL: NSURL? { return getImageURLwithType("large") }
    
    func getImageURLwithType(type: String) -> NSURL?
    {
        for link in self.links {
            if link.type == type {
                return link.url
            }
        }
        return nil
    }
}

class EditableWaypoint: GPX.Waypoint {
    // Draggable waypoint
    override var coordinate: CLLocationCoordinate2D {
        get { return super.coordinate }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    override var thumbnailURL: NSURL? { return imageURL }
    override var imageURL: NSURL? { return links.first?.url }
}
