//
//  ItemInfoViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/7.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class ItemInfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    weak var objectMenuItem : NSManagedObject?
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    @IBAction func priceChanged(_ sender: AnyObject) {
        objectMenuItem?.setValue(Double(priceField.text!), forKey: "price")
    }
    
    @IBAction func backgroundTapped(_ sender: AnyObject) {
        priceField.resignFirstResponder()
    }
    
    @IBAction func photoTapped(_ sender: AnyObject) {
        pickImage(sourceType: .photoLibrary)
    }

    @IBAction func cameraTapped(_ sender: AnyObject) {
        pickImage(sourceType: .camera)
    }

    func pickImage(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes[0] = kUTTypeImage as String
        imagePicker.allowsEditing = true
        imagePicker.sourceType = sourceType
        if sourceType != UIImagePickerControllerSourceType.camera && UIDevice.current.model.contains("iPad") {
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.popover
        }
        present(imagePicker, animated: true, completion: nil)
        if imagePicker.modalPresentationStyle == UIModalPresentationStyle.popover, let presentationController = imagePicker.popoverPresentationController {
            presentationController.permittedArrowDirections = [.left, .right]
            presentationController.sourceView = view
            presentationController.sourceRect = imageView.frame
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = objectMenuItem?.value(forKey: "name") as? String
        // categoryLabel.text = categoryName
        categoryLabel.text = objectMenuItem?.value(forKeyPath: "category.name") as? String
        priceField.text = "\(objectMenuItem?.value(forKey: "price") as! Double)"
        if let iconData = objectMenuItem?.value(forKey: "icon") as? Data {
            imageView.image = UIImage(data: iconData)
        }
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        photoButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Adopt to delegate for UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        if let image = imageView.image {
            if let data = UIImagePNGRepresentation(image) {
                objectMenuItem?.setValue(data, forKey: "icon")
            } else if let data = UIImageJPEGRepresentation(image, 1.0) {
                objectMenuItem?.setValue(data, forKey: "icon")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK - Tool func
    func sell() {
        objectMenuItem?.setValue(true, forKey: "on_stock")
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func unsell() {
        objectMenuItem?.setValue(false, forKey: "on_stock")
        let _ = navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
