//
//  AppDelegate.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    /*
    Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
    Return true if the delegate successfully handled the request or false if the attempt to open the URL resource failed.
    */
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    {
        // works here when using AirDrop drop a gpx file on a device
        print("file url in AppDelegate: \(url)")
        
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: Constants.OpenFileNotification, object: self, userInfo: [Constants.OpenFileKey: url])
        center.postNotification(notification)   // Post a notification when a GPX file arrives
        
        return true
    }

}
