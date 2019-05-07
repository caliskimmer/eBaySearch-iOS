//
//  WishListViewDelegate.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/13/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol WishListViewDelegate: class {
    func requestedDetails(_ wishListView: WishListView, forData data: JSON)
}
