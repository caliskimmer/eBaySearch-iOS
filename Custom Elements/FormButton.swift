//
//  FormButton.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/4/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit

@IBDesignable
class FormButton: UIButton {
    @IBInspectable var borderRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = CGFloat(newValue)
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
