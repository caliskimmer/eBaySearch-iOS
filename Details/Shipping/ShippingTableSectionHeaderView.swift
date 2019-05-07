//
//  ShippingTableSectionHeaderView.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/12/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit

class ShippingTableSectionHeaderView: UIView {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet var contentView: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
        Bundle.main.loadNibNamed("ShippingTableSectionHeaderView", owner: self, options: nil)
        self.addSubview(contentView)
        
        let borderTop = CALayer()
        let borderBottom = CALayer()
        let padding:CGFloat = 5
        borderTop.backgroundColor = UIColor(red: 231.0/255.0, green: 231.0/255.0, blue: 231.0/255.0, alpha: 1.0).cgColor
        borderBottom.backgroundColor = UIColor(red: 231.0/255.0, green: 231.0/255.0, blue: 231.0/255.0, alpha: 1.0).cgColor
        borderTop.frame = CGRect(x: contentView.frame.minX+padding, y: contentView.frame.minY, width: contentView.frame.width-padding*3, height: 1.0)
        borderBottom.frame = CGRect(x: contentView.frame.minX+padding, y: contentView.frame.maxY, width: contentView.frame.width-padding*3, height: 1.0)

        contentView.layer.addSublayer(borderTop)
        contentView.layer.addSublayer(borderBottom)
        
        contentView.frame = self.frame
    }
}
