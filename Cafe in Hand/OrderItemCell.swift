//
//  OrderItemCell.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/3.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit

protocol OrderItemCellDelegate {
    func amountChanged(sender: OrderItemCell, deltaAmount: Int)
}

class OrderItemCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var amountStepper: UIStepper!
    @IBOutlet weak var iconImageView: UIImageView!

    @IBAction func amountStepperChanged(_ sender: AnyObject) {
        let oldVal = Int(amountLabel.text!)!
        let newVal = Int(amountStepper.value)
        let deltaVal = newVal - oldVal
        amountLabel.text = "\(newVal)"
        let subTotal = amountStepper.value * Double(priceLabel.text!)!
        totalLabel.text = "\(subTotal)"
        delegate?.amountChanged(sender: self, deltaAmount: deltaVal)
    }
    
    var delegate: OrderItemCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(name: String, price: Double, image: Data?, amount: Int) {
        nameLabel.text = name
        priceLabel.text = "\(price)"
        if (image != nil) {
            iconImageView.image = UIImage(data: image!)
        } else {
            iconImageView.image = nil
        }
        amountStepper.value = Double(amount)
        amountLabel.text = "\(amount)"
        totalLabel.text = "\(price * Double(amount))"
    }

}
