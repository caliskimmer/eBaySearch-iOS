//
//  ResultsTableViewCell.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/10/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON

class ResultsTableViewCell: UITableViewCell {
    weak var delegate: ResultsCellDelegate?
    var data: JSON?

    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var itemShipping: UILabel!
    @IBOutlet weak var itemZip: UILabel!
    @IBOutlet weak var itemCondition: UILabel!
    @IBOutlet weak var itemWishListStatus: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func toggleWishList(_ sender: UIButton) {
        if itemWishListStatus.backgroundImage(for: .normal) == UIImage(named: "wishListEmpty") {
            itemWishListStatus.setBackgroundImage(UIImage(named: "wishListFilled"), for: .normal);
            delegate?.wishListToggledOn(self)
        } else {
            itemWishListStatus.setBackgroundImage(UIImage(named: "wishListEmpty"), for: .normal);
            delegate?.wishListToggledOff(self)
        }
    }
}
