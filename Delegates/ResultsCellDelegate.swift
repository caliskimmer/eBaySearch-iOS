//
//  ResultsCellDelegate.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/10/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import Foundation

protocol ResultsCellDelegate: class {
    func wishListToggledOff(_ resultsCell: ResultsTableViewCell)
    func wishListToggledOn(_ resultsCell: ResultsTableViewCell)
}
