//
//  SellableViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/30.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class SellableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, OrderItemCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    internal var amountList : [Double] = []
    internal var fetchController : NSFetchedResultsController<NSFetchRequestResult>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        // use fetched results controller
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MenuItem")
        request.predicate = NSPredicate(format: "%K == YES", "on_stock")
        request.sortDescriptors = [NSSortDescriptor(key: "category.name", ascending: true)]
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let context = appDelegate?.persistentContainer.viewContext {
            fetchController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "category.name", cacheName: nil)
            fetchController?.delegate = self
            do {
                try fetchController?.performFetch()
            } catch {
                fatalError("Failed to fetch on first time")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Order item cell delegate
    func amountChanged(sender: OrderItemCell, delta: Double) {
        let index = sender.index
        amountList[index] = sender.amountStepper.value
        // unimplement to update total price
    }

    // MARK: - Feched results controller delegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections([sectionIndex], with: .automatic)
        case .delete:
            tableView.deleteSections([sectionIndex], with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            amountList.insert(0, at: newIndexPath!.item)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            amountList.remove(at: indexPath!.item)
        case .update:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Order Item Cell", for: indexPath!) as! OrderItemCell
            configure(for: cell, objMenuItem: anObject, index: indexPath!.item)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // calculate sections count from fetched result controller
        return (fetchController?.sections?.count)!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // calculate rows count of one section from fetched result controller
        guard fetchController?.sections?.isEmpty == false else {
            return 0
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order Item Cell", for: indexPath) as! OrderItemCell

        // Configure the cell with info from fetched result controller
        configure(for: cell, objMenuItem: fetchController?.object(at: indexPath), index: indexPath.item)
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard fetchController?.sections?.isEmpty == false else {
            return nil
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.name
        }
        return nil
    }
    
    // tool func for configure table view cell with managed object
    func configure(for cell: OrderItemCell?, objMenuItem: Any, index: Int) {
        cell?.delegate = self
        if let obj = objMenuItem as? NSManagedObject {
            let name = obj.value(forKey: "name") as? String
            let price = obj.value(forKey: "price") as? Double
            let icon = obj.value(forKey: "icon") as? Data
            let amountVal = index < amountList.count ? amountList[index] : 0.0
            cell?.configure(name: name, price: price, image: icon, amount: amountVal, at: index)
        }
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
