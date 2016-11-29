//
//  NewItemViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/29.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class NewItemViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var onStockSwitch: UISwitch!
    
    var categories : [String] = []

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
        
        // insert new menu item
        if let entityDescription = NSEntityDescription.entity(forEntityName: "MenuItem", in: context) {
            let newObj = NSManagedObject(entity: entityDescription, insertInto: context)
            newObj.setValue(nameTextField.text, forKey: "name")
            newObj.setValue(Double(priceTextField.text!), forKey: "price")
            newObj.setValue(onStockSwitch.isOn, forKey: "on_stock")
            newObj.setValue(categoryObj, forKey: "category")
            if newObj.hasFault(forRelationshipNamed: "category") {
                fatalError("Failed to check relationship in MenuItem")
            }
        }
        
        reset()
    }
    
    // clear controls
    func reset() {
        nameTextField.text = ""
        categoryTextField.text = ""
        priceTextField.text = ""
        iconImageView.image = nil
        onStockSwitch.isOn = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        reset()
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
            categories.append("User Defined")
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
    
    // MARK: Adapt to data source and delegate for picker view
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
