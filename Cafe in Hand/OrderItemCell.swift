//
//  OrderItemCell.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/3.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit

protocol OrderItemCellDelegate {
    func totalChanged(sender: OrderItemCell)
}

class OrderItemCell: UITableViewCell {

    var delegate: OrderItemCellDelegate?
    var amount: Int {
        get {
            return Int(amountStepper.value)
        }
        set {
            amountStepper.value = Double(newValue)
            amountStepperChanged(amountStepper)
        }
    }
    var price: Double {
        get {
            return Double(priceLabel.text!)!
        }
        set {
            priceLabel.text = "\(newValue)"
            let oldTotal = Double(totalLabel.text!)!
            let newTotal = price * amountStepper.value
            totalLabel.text = "\(newTotal)"
            if newTotal != oldTotal {
                delegate?.totalChanged(sender: self)
            }
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var amountStepper: UIStepper!
    @IBOutlet weak var iconImageView: UIImageView!

    @IBAction func amountStepperChanged(_ sender: AnyObject) {
        amountLabel.text = "\(Int(amountStepper.value))"
        let oldTotal = Double(totalLabel.text!)!
        let newTotal = amountStepper.value * Double(priceLabel.text!)!
        totalLabel.text = "\(newTotal)"
        if newTotal != oldTotal {
            delegate?.totalChanged(sender: self)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(name: String, image: Data?, price: Double) {
        nameLabel.text = name
        if (image != nil) {
            iconImageView.image = UIImage(data: image!)
        } else {
            iconImageView.image = nil
        }
        self.price = price
    }
    
}
