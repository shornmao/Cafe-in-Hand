//
//  OrderInfoCell.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/29.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit

class OrderInfoCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var subtotalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
