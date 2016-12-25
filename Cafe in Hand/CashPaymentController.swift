//
//  CashPaymentController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/12.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit

protocol CashPaymentControllerDelegate {
    func dismissed(_ controller: CashPaymentController, cancel: Bool)
}

class CashPaymentController: UIViewController {
    
    var payment = 0.0
    
    var dismissionDelegate: CashPaymentControllerDelegate?

    @IBOutlet weak var payLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var chargeField: UITextField!

    @IBAction func doneTapped(_ sender: AnyObject) {
        dismissionDelegate?.dismissed(self, cancel: false)
    }

    @IBAction func cancelTapped(_ sender: Any) {
        dismissionDelegate?.dismissed(self, cancel: true)
    }
    
    @IBAction func chargeEndEditing(_ sender: AnyObject) {
        if let charge = Double(chargeField.text!) {
            changeLabel.text = "\(charge - payment)"
        }
    }

    @IBAction func chargeOnExit(_ sender: AnyObject) {
        if let field = sender as? UITextField {
            field.resignFirstResponder()
        }
    }

    @IBAction func backgroundTouched(_ sender: AnyObject) {
        chargeField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        payLabel.text = "\(payment)"
        changeLabel.text = "0.00"
        chargeField.text = "0.00"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
