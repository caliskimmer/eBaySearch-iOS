//
//  WishListView.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/10/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import Alamofire
import Toast_Swift

class WishListView: UIView {
    var items:[String] = []
    var totalCost:Float = 0.0
    var delegate:WishListViewDelegate?

    @IBOutlet weak var itemTableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil {
                items.append(key)
                
                let itemData = JSON.init(parseJSON: value as! String)
                if let price = itemData["price"].string {
                    let start = price.index(price.startIndex, offsetBy: 1)
                    totalCost += Float(String(price[start...])) ?? 0.0
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func setupItemTable() {
        itemTableView.delegate = self
        itemTableView.dataSource = self
    }
    
    func reloadWishList(withData reloadData: Bool) {
        if items.count == 0 {
            noItemsLabel.isHidden = false
            totalLabel.isHidden = true
            totalCostLabel.isHidden = true
            itemTableView.isHidden = true
        } else {
            let itemText = items.count == 1 ? "item" : "items"
            totalLabel.text = "WishList Total(\(items.count) \(itemText)):"
            totalCostLabel.text = "$\((totalCost*100).rounded()/100)"
            totalLabel.isHidden = false
            totalCostLabel.isHidden = false
            noItemsLabel.isHidden = true
            itemTableView.isHidden = false
        }
        
        if reloadData {
            itemTableView.reloadData()
        }
    }
}

// MARK: itemTableView delegate methods
extension WishListView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wishListCell", for: indexPath) as! WishListTableViewCell
        
        // Configure the cell...
        let item = items[indexPath.row]
        let defaults = UserDefaults.standard
        let result = JSON.init(parseJSON: defaults.string(forKey: item)!)

        // Configure image and fetch asynchronously
        DispatchQueue.global().async {
            if let url = URL(string:(result["image"].string ?? "")) {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        cell.itemImage.image = UIImage(data: data)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    cell.itemImage.image = UIImage(named: "default")
                }
            }
        }
        
        cell.itemTitle.text = (result["title"].string ?? "")
        cell.itemPrice.text = (result["price"].string ?? "")
        cell.itemZip.text = (result["zip"].string ?? "")
        cell.itemShipping.text = (result["shipping"]["type"].string ?? "")
        
        // Configure condition
        let conditionId = (result["condition"].string ?? "")
        var condition = ""
        switch(conditionId) {
        case "1000":
            condition = "NEW"
            break
        case "2000", "2500":
            condition = "REFURBISHED"
            break
        case "3000", "4000", "5000", "6000":
            condition = "USED"
            break
        default:
            condition = "NA"
            break
        }
        cell.itemCondition.text = condition
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let item = items[indexPath.row]
            
            let itemData = JSON.init(parseJSON: UserDefaults.standard.string(forKey: item)!)
            if let price = itemData["price"].string {
                let start = price.index(price.startIndex, offsetBy: 1)
                totalCost -= Float(String(price[start...])) ?? 0.0
            }
            
            UserDefaults.standard.removeObject(forKey: item)
            items.remove(at: indexPath.row)
            itemTableView.deleteRows(at: [indexPath], with: .fade)
            
            self.superview!.makeToast("\(itemData["title"].stringValue) was removed from the wishList", duration: 2.0)
        }
        
        // revert to empty view if no items left
        if items.count == 0 {
            reloadWishList(withData: false)
        } else {
            totalCostLabel.text = "$\((totalCost*100).rounded()/100)"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //construct query
        let item = items[indexPath.row]
        let data = JSON.init(parseJSON: UserDefaults.standard.string(forKey: item)!)
        
        delegate?.requestedDetails(self, forData: data)
    }
}
