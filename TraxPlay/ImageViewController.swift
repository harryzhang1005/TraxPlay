//
//  ImageViewController.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate
{
    // MARK: - Public API
    
    var imageURL: NSURL? {  // Model
        didSet {
            image = nil // clean first
            if view.window != nil { self.fetchImage() } // make sure view is on screen
        }
    }
    
    // MARK: - Private
    
    private var imageView = UIImageView()
    
    private var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageView.sizeToFit()   // Call this method when you want to resize the current view so that it uses the most appropriate amount of space.
            
            // Note: Here scrollView? to compatible image = nil
            scrollView?.contentSize = imageView.frame.size   // Key point: reset scroll view content size
            spinner?.stopAnimating()
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size   // Key point: critical to set this
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    func fetchImage()
    {
        if let imgURL = imageURL
        {
            spinner.startAnimating()
            //print("img url: \(imgURL.absoluteString)")

            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let imageData = NSData(contentsOfURL: imgURL)
                
                dispatch_async(dispatch_get_main_queue()) {
                    if imgURL == self.imageURL {    // make sure same image url as starting download
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)
                        } else {
                            self.image = nil
                        }
                    }
                }//mainQ
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        scrollView.addSubview(imageView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if image == nil { fetchImage() }
    }
    
    // MARK: - UIScrollViewDelegate method
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
