//
//  NewItemViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/29.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class NewItemViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var onStockSwitch: UISwitch!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    var categories : [String] = []

    @IBAction func photoTapped(_ sender: AnyObject) {
        pickImage(sourceType: .photoLibrary)
    }

    @IBAction func cameraTapped(_ sender: AnyObject) {
        pickImage(sourceType: .camera)
    }
    
    @IBAction func resetTapped(_ sender: AnyObject) {
        reset()
    }

    @IBAction func saveTapped(_ sender: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        var categoryObj : NSManagedObject?
        if categoryTextField.isEnabled {
            // insert new category
            if let entityDescription = NSEntityDescription.entity(forEntityName: "Category", in: context) {
                let newObj = NSManagedObject(entity: entityDescription, insertInto: context)
                newObj.setValue(categoryTextField.text, forKey: "name")
                categoryObj = newObj
                
                // update category picker view
                categories.append(categoryTextField.text!)
                categoryPickerView.reloadAllComponents()
            }
        } else {
            // fetch existing category
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
            request.predicate = NSPredicate(format: "%K = %@", "name", categories[categoryPickerView.selectedRow(inComponent: 0)])
            do {
                let objList = try context.fetch(request)
                if objList.count > 0 {
                    categoryObj = objList[0] as? NSManagedObject
                }
            } catch {
                fatalError("Failed to fetch category")
            }
        }
/*
        var error : NSError?
        do {
            try categoryObj?.validateForUpdate()
        } catch {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Title for Error Message Box"), message: error.localizedDescription, preferredStyle: .alert)
            let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Default Button Caption"), style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
*/        
        // insert new menu item
        if let entityDescription = NSEntityDescription.entity(forEntityName: "MenuItem", in: context) {
            let newObj = NSManagedObject(entity: entityDescription, insertInto: context)
            newObj.setValue(nameTextField.text, forKey: "name")
            newObj.setValue(Double(priceTextField.text!), forKey: "price")
            newObj.setValue(onStockSwitch.isOn, forKey: "on_stock")
            if let image = iconImageView.image {
                if let data = UIImagePNGRepresentation(image) {
                    newObj.setValue(data, forKey: "icon")
                } else if let data = UIImageJPEGRepresentation(image, 1.0) {
                    newObj.setValue(data, forKey: "icon")
                }
            }
            newObj.setValue(categoryObj, forKey: "category")
        }
        
        reset()
    }
    
    // clear controls and data
    func reset() {
        nameTextField.text = ""
        categoryTextField.text = ""
        priceTextField.text = ""
        iconImageView.image = nil
        onStockSwitch.isOn = true
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
            presentationController.sourceView = view
            presentationController.sourceRect = view.frame
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        reset()
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        photoButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // update candicates for Picker View for each viewing
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        do {
            let objList = try context.fetch(request)
            categories.removeAll()
            categories.append(NSLocalizedString("User Defined", comment: "Special category place holder to enable user define"))
            for obj in objList {
                if let managedObj = obj as? NSManagedObject {
                    categories.append(managedObj.value(forKey: "name") as! String)
                }
            }
            categoryPickerView.reloadAllComponents()
            categoryPickerView.selectRow(0, inComponent: 0, animated: false)
            categoryTextField.isEnabled = true
        } catch {
            fatalError("failed to fetch Category")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // save database before leaving current view
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.saveContext()
    }
    
    // MARK: Adopt to data source and delegate for picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.isEnabled = (row == 0)
    }
    
    // MARK: Adopt to delegate for UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        iconImageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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
