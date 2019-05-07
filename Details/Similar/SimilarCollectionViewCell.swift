//
//  SimilarCollectionViewCell.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/13/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit

class SimilarCollectionViewCell: UICollectionViewCell {
    var linkURL: String?
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var shippingPrice: UILabel!
    @IBOutlet weak var daysLeft: UILabel!
    @IBOutlet weak var price: UILabel!
    
}
