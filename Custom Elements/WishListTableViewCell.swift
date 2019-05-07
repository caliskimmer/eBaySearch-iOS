//
//  WishListTableViewCell.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/11/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON

class WishListTableViewCell: UITableViewCell {    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var itemShipping: UILabel!
    @IBOutlet weak var itemZip: UILabel!
    @IBOutlet weak var itemCondition: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
