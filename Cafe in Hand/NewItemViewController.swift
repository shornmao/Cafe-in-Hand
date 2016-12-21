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

class NewItemViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSFetchedResultsControllerDelegate {
    
    static let defaultItemName = NSLocalizedString("No Named", comment: "Default menu item name")
    static let defaultCategoryName = NSLocalizedString("User Defined", comment: "Default category name")
    static let defaultPrice = 0.0
    static let defaultImage : UIImage? = nil
    static let defaultOnStock = true
    static let defaultCategoryRow = 0

    var categoriesFetchController : NSFetchedResultsController<NSFetchRequestResult>?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var onStockSwitch: UISwitch!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!

    @IBAction func photoTapped(_ sender: AnyObject) {
        pickImage(sourceType: .photoLibrary)
    }

    @IBAction func cameraTapped(_ sender: AnyObject) {
        pickImage(sourceType: .camera)
    }
    
    @IBAction func categoryEditingEnd(_ sender: AnyObject) {
        guard categoryTextField == sender as? UITextField else {
            return
        }
        if let row = categoryAtRow(categoriesFetchController, name: categoryTextField.text!) {
            categoryPickerView.selectRow(row + 1, inComponent: 0, animated: true)
            categoryTextField.isEnabled = false
        }
    }
    
    @IBAction func resetTapped(_ sender: AnyObject) {
        reset()
    }
    
    @IBAction func textFieldDoneEditing(_ sender: AnyObject) {
        if let textField = sender as? UITextField {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func backgroundTapped(_ sender: AnyObject) {
        categoryTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        priceTextField.resignFirstResponder()
    }

    @IBAction func saveTapped(_ sender: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let categoryName = categoryTextField.text!

        if categoryTextField.isEnabled  {
            // validate category name
            guard !categoryName.isEmpty else {
                presentAlertInvalidation(NSLocalizedString("Do not use blank category name.", comment: "Error message for input blank category name"))
                return
            }
            guard categoryName != NewItemViewController.defaultCategoryName else {
                presentAlertInvalidation(NSLocalizedString("Do not use placeholder as category name.", comment: "Error message for input placeholder category name"))
                return
            }
        }

        // validate item name
        let itemName = nameTextField.text!
        guard !itemName.isEmpty else {
            presentAlertInvalidation(NSLocalizedString("Do not use blank item name.", comment: "Error message for input blank item name"))
            return
        }
        guard itemName != NewItemViewController.defaultItemName else {
            presentAlertInvalidation(NSLocalizedString("Do not use placeholder as item name.", comment: "Error message for input placeholder item name"))
            return
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MenuItem")
        request.predicate = NSPredicate(format: "%K = %@", "name", itemName)
        do {
            let objList = try context.fetch(request)
            guard objList.isEmpty else {
                presentAlertInvalidation(NSLocalizedString("Item name exists already.", comment: "Error message for duplicated item"))
                return
            }
        } catch {
            fatalError("Failed to fetch MenuItem with specified name")
        }
        
        // validate item price
        guard let price = Double(priceTextField.text!) else {
            presentAlertInvalidation(NSLocalizedString("Use decimal like '1.05' for price input.", comment: "Error message for invalidate price format"))
            return
        }

        var categoryObj : NSManagedObject?
        if categoryTextField.isEnabled {
            // insert new category
            categoryObj = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            categoryObj!.setValue(categoryName, forKey: "name")
        } else {
            // take back category regardless new or existing
            // MARK - fetched results controller hasn't hanlded changing notification, only can fetch again
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
            request.predicate = NSPredicate(format: "%K == %@", "name", categoryName)
            do {
                let objsCategory = try context.fetch(request)
                guard !objsCategory.isEmpty else {
                    presentAlertInvalidation(NSLocalizedString("Category name dosen't exist.", comment: "Error message for absent category name"))
                    return
                }
                categoryObj = objsCategory[0] as? NSManagedObject
            } catch {
                fatalError("Failed to fetch <Category> in data modal")
            }
        }
        
        // insert new item
        if let entityDescription = NSEntityDescription.entity(forEntityName: "MenuItem", in: context) {
            let newObj = NSManagedObject(entity: entityDescription, insertInto: context)
            newObj.setValue(itemName, forKey: "name")
            newObj.setValue(price, forKey: "price")
            newObj.setValue(onStockSwitch.isOn, forKey: "on_stock")
            if let image = iconImageView.image {
                if let data = UIImagePNGRepresentation(image) {
                    newObj.setValue(data, forKey: "icon")
                } else if let data = UIImageJPEGRepresentation(image, 1.0) {
                    newObj.setValue(data, forKey: "icon")
                }
            }
            newObj.setValue(categoryObj!, forKey: "category")
        } else {
            fatalError("Failed to access <MenuItem> in data model")
        }
        
        // MARK - Debug Purpose
//        appDelegate.saveContext()
        
        // Acknowledge for successful new item
        let alert = UIAlertController(title: NSLocalizedString("Acknowledge", comment: "Title for Info Message Box"), message: NSLocalizedString("New item is input successfully.", comment: "Info message for new item input"), preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK button"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)

        // reset to default value
        reset()
    }
    
    // clear controls and data to default status
    func reset() {
        nameTextField.text = NewItemViewController.defaultItemName
        categoryTextField.text = NewItemViewController.defaultCategoryName
        categoryTextField.isEnabled = true
        priceTextField.text = "\(NewItemViewController.defaultPrice)"
        iconImageView.image = NewItemViewController.defaultImage
        onStockSwitch.isOn = NewItemViewController.defaultOnStock
        categoryPickerView.selectRow(NewItemViewController.defaultCategoryRow, inComponent: 0, animated: true)
    }
    
    // show image picker view
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
            presentationController.sourceRect = photoButton.frame
        }
    }
    
    // locate category name in row of picker view
    func categoryAtRow(_ fetchController: NSFetchedResultsController<NSFetchRequestResult>?, name: String) -> Int? {
        if let rows = fetchController?.sections?[0].numberOfObjects {
            for row in 0..<rows {
                if let obj = fetchController?.object(at: IndexPath(row: row, section: 0)) as? NSManagedObject {
                    if obj.value(forKey: "name") as? String == name {
                        return row
                    }
                }
            }
        }
        return nil
    }
    
    // locate category object
    func categoryAtObject(_ fetchController: NSFetchedResultsController<NSFetchRequestResult>?, name: String) -> NSManagedObject? {
        if let rows = fetchController?.sections?[0].numberOfObjects {
            for row in 0..<rows {
                if let obj = fetchController?.object(at: IndexPath(row: row, section: 0)) as? NSManagedObject {
                    if obj.value(forKey: "name") as? String == name {
                        return obj
                    }
                }
            }
        }
        return nil
    }

    // alert for invalidated user input
    func presentAlertInvalidation(_ errorMessage: String) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Title for Error Message Box"), message: errorMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK button"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        photoButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)

        // use fetched results controller to monitor changes of Category
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        let sorter = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sorter]
        let context = appDelegate.persistentContainer.viewContext
        categoriesFetchController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        categoriesFetchController?.delegate = self
        do {
            try categoriesFetchController?.performFetch()
        } catch {
            fatalError("Failed to fetch and monitor all from Category")
        }
        
        reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: Adopt to delegate for fetched results controller
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        categoryPickerView.reloadComponent(0)
    }
    
    // MARK: Adopt to data source and delegate for picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // at least 1 row exists in the first named <User Defined> not from data base
        if let sectionInfo = categoriesFetchController?.sections?[0] {
            return sectionInfo.numberOfObjects + 1
        }
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == NewItemViewController.defaultCategoryRow {
            return NewItemViewController.defaultCategoryName
        }
        let obj = categoriesFetchController?.object(at: IndexPath(row: row - 1, section: 0)) as? NSManagedObject
        return obj?.value(forKey: "name") as? String
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == NewItemViewController.defaultCategoryRow {
            categoryTextField.isEnabled = true
            categoryTextField.text = NewItemViewController.defaultCategoryName
        } else {
            categoryTextField.isEnabled = false
            if let obj = categoriesFetchController?.object(at: IndexPath(row: row - 1, section: 0)) as? NSManagedObject, let name = obj.value(forKey: "name") as? String {
                categoryTextField.text = name
            }            
        }
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
