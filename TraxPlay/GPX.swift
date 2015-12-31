//
//  GPX.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import UIKit

/* Waypoint Sample - GPX is also a XML file, GPX file contains multi-waypoints

<wpt lat="50.7653464" lon="-118.2072668">
    <name>Top of First Run</name>
    <desc>Incredible views from up here.</desc>
    <link href="http://cs193p.stanford.edu/Images/Crag.jpg"><type>large</type></link>
    <link href="http://cs193p.stanford.edu/Images/Crag.png"><type>thumbnail</type></link>
</wpt>

Q: What's the GPX file tags ?
http://www.topografix.com/gpx/1/1/

*/
class GPX: NSObject
{
    // MARK: - Public API
    
    var waypoints = [Waypoint]()
    
    typealias GPXCompletionHandler = (GPX?) -> Void
    
    class func parse(url: NSURL, completionHandler: GPXCompletionHandler)
    {
        GPX(url: url, completionHandler: completionHandler).gpxParse()
    }
    
    // MARK: - Public Class
    
    class Waypoint: NSObject
    {
        /// 1. A waypoint 's construct elements
        var latitude: Double
        var longitude: Double
        init(lati: Double, lgti: Double) { self.latitude = lati; self.longitude = lgti }
        
        /// 2. A waypoint 's attributes
        var waypointAttributes = [String: String]()     // name, desc, link, time
        
        var name: String? {
            get { return waypointAttributes["name"] }
            set { waypointAttributes["name"] = newValue }
        }
        
        var info: String? {
            get { return waypointAttributes["desc"] }
            set { waypointAttributes["desc"] = newValue }
        }
        
        var links = [Link]()    // A waypoint contains two Link
        
        lazy var date: NSDate? = self.waypointAttributes["time"]?.gpxDate
    }
    
    // <link href="http://cs193p.stanford.edu/Images/Crag.jpg"><type>large</type></link>
    // <link href="http://cs193p.stanford.edu/Images/Crag.png"><type>thumbnail</type></link>
    class Link
    {
        /// 1. A link 's construct element
        var href: String   // image url string
        init(href: String) { self.href = href }
        
        /// 2. A link 's attributes
        var linkAttributes = [String: String]()
        
        var url: NSURL? { return NSURL(string: href) }
        var text: String? { return linkAttributes["text"] } // in this case, text is empty
        var type: String? { return linkAttributes["type"] } // large or thumbnail
    }
    
    // MARK: - Private Implementation
    
    private let url: NSURL  // gpx file URL
    private let completionHandler: GPXCompletionHandler
    
    private init(url: NSURL, completionHandler: GPXCompletionHandler) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    private var waypoint: Waypoint? // Extensions may not contain stored properties, so this should put original class GPX
    private var link: Link?
    private var input = ""

    private func fail() { completeWithFlag(flag: false) }
    private func succeed() { completeWithFlag(flag: true) }
    private func completeWithFlag(flag flag: Bool) {
        dispatch_async(dispatch_get_main_queue()) { self.completionHandler(flag ? self : nil) }
    }
    
    private func gpxParse()
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            if let validData = NSData(contentsOfURL: self.url) {
                let parser = NSXMLParser(data: validData)
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                parser.parse()
            } else { self.fail() }
        }//block
    }
    
}

/* Waypoint Sample - GPX is also a XML file, GPX file contains multi-waypoints

<wpt lat="50.7653464" lon="-118.2072668">
    <name>Top of First Run</name>
    <desc>Incredible views from up here.</desc>
    <link href="http://cs193p.stanford.edu/Images/Crag.jpg"><type>large</type></link>
    <link href="http://cs193p.stanford.edu/Images/Crag.png"><type>thumbnail</type></link>
</wpt>

*/
extension GPX: NSXMLParserDelegate
{
    func parserDidEndDocument(parser: NSXMLParser) { succeed() }
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) { fail() }
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) { fail() }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) { input += string }
    
    // Sent by a parser object to its delegate when it encounters a start tag for a given element.
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
        switch elementName {
            case "rtept", "trkpt", "wpt":
                let latitude = NSString(string: attributeDict["lat"]!).doubleValue
                let longitude = NSString(string: attributeDict["lon"]!).doubleValue
                waypoint = Waypoint(lati: latitude, lgti: longitude)
            case "link":
                link = Link(href: attributeDict["href"]!)
            default: break
        }
    }
    
    // Sent by a parser object to its delegate when it encounters an end tag for a specific element.
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        switch elementName {
            case "wpt":
                if waypoint != nil {
                    waypoints.append(waypoint!);
                    waypoint = nil
                }
            case "link":
                if link != nil {
                    if waypoint != nil {
                        waypoint?.links.append(link!)
                    }
                }
                link = nil
            default:
                if link != nil {
                    link?.linkAttributes[elementName] = input.trimmed
                } else if waypoint != nil {
                    waypoint?.waypointAttributes[elementName] = input.trimmed
                }
                input = ""
        }
    }
}

// MARK: - Extensions

private extension String {
    // Trim white space and newline character in string
    var trimmed: String {
        return (self as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

extension String {
    // Convert string to date
    var gpxDate: NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
        return dateFormatter.dateFromString(self)
    }
}
