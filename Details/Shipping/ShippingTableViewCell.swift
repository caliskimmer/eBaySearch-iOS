//
//  ShippingTableViewCell.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/12/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit

class ShippingTableViewCell: UITableViewCell {
    @IBOutlet weak var col1: UILabel!
    @IBOutlet weak var col2: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
