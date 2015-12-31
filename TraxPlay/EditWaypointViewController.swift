//
//  EditWaypointViewController.swift
//  TraxPlay
//
//  Created by Harvey Zhang on 12/30/15.
//  Copyright © 2015 HappyGuy. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditWaypointViewController: UIViewController
{
    // MARK: - Public API
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    // MARK: - Private
    
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameTextField.becomeFirstResponder()
        updateUI()
    }
    
    func updateUI()
    {
        if let waypoint = waypointToEdit {
            nameTextField.text = waypoint.name
            infoTextField.text = waypoint.info
        }
        updateImage()
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Image
    
    var imageView = UIImageView()
    
    @IBOutlet weak var imageContainerView: UIView! {
        didSet {
            imageContainerView.addSubview(imageView)
        }
    }
    
    func updateImage()
    {
        if let url = waypointToEdit?.imageURL {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { [weak self] in
                if let imageData = NSData(contentsOfURL: url)
                {
                    if url == self?.waypointToEdit?.imageURL {
                        if let image = UIImage(data: imageData) {
                            dispatch_async(dispatch_get_main_queue()) {
                                self?.imageView.image = image
                                self?.makeRoomForImage()
                            }
                        }//image
                    }
                }//imageData
            }
        }
    }
    
    // Instead of autolayout
    func makeRoomForImage()
    {
        var extraHeight: CGFloat = 0
        
        if imageView.image?.aspectRatio > 0
        {
            if let width = imageView.superview?.frame.size.width {
                let height = width / imageView.image!.aspectRatio
                extraHeight = height - imageView.frame.height
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
        }
        else {
            extraHeight = -imageView.frame.height
            imageView.frame = CGRectZero
        }
        
        /* preferredContentSize ?   --   The preferred size for the view controller’s view.
        The value in this property is used primarily when displaying the view controller’s content in a popover but may also be used in other situations. Changing the value of this property while the view controller is being displayed in a popover animates the size change; however, the change is not animated if you specify a width or height of 0.0.
        The preferredContentSize is used for any container laying out a child view controller.
        */
        preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
    }
    
    func saveImageToWaypoint()
    {
        if let image = imageView.image {
            if let imageData = UIImageJPEGRepresentation(image, 1.0)
            {
                let fileManager = NSFileManager()   // start a new thread
                if let docsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
                {
                    let unique = NSDate.timeIntervalSinceReferenceDate()
                    let url = docsDir.URLByAppendingPathComponent("\(unique).jpg")
                    if imageData.writeToURL(url, atomically: true) {
                        waypointToEdit?.links = [GPX.Link(href: url.absoluteString)]
                    }
                }
            }//imageData
        }
    }
    
    @IBAction func takePhoto()
    {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let ipc = UIImagePickerController()
            ipc.sourceType = .Camera
            ipc.mediaTypes = [kUTTypeImage as String]
            ipc.delegate = self
            ipc.allowsEditing = true
            presentViewController(ipc, animated: true, completion: nil)
        }
    }
    
    private var ntfObserver: NSObjectProtocol?
    private var itfObserver: NSObjectProtocol?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startObservingTextFields()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingTextFields()
    }
    
    private func startObservingTextFields()
    {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        ntfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: nameTextField, queue: queue)  { noti in
            if let waypoint = self.waypointToEdit {
                waypoint.name = self.nameTextField.text
            }
        }
        
        itfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: infoTextField, queue: queue)  { noti in
            if let waypoint = self.waypointToEdit {
                waypoint.info = self.infoTextField.text
            }
        }
    }
    
    private func stopObservingTextFields()
    {
        let center = NSNotificationCenter.defaultCenter()
        if let ntfo = ntfObserver {
            center.removeObserver(ntfo)
        }
        if let itfo = itfObserver {
            center.removeObserver(itfo)
        }
    }

}

// Dismiss keyboard
extension EditWaypointViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Take a photo via camera
extension EditWaypointViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil { image = info[UIImagePickerControllerOriginalImage] as? UIImage }
        imageView.image = image
        makeRoomForImage()
        saveImageToWaypoint()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        return size.height != 0 ? size.width/size.height : 0
    }
}
