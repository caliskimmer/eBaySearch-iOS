//
//  ShippingTableViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/11/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import Alamofire

class ShippingTableViewController: UITableViewController {
    var itemID: String!
    var itemDetails: JSON?
    var tableData: [String:[String]]?
    var numTableSections: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelection = false
        
        // load item details
        var params = [String: Any]()
        params["itemId"] = itemID
        let url = "\(Constants.SERVER_PATH)/shopping"
        Alamofire.request(url, parameters: params).responseJSON { [weak self] response in
            guard let jsonString = response.result.value else {
                print("json string doesn't exist")
                return
            }
            let json = JSON(jsonString)
            self?.itemDetails = json
            
            self?.tableData = self?.setupTableData()
            self?.numTableSections = self?.tableData?.count ?? 0
            self?.tableView.reloadData()
            
            SwiftSpinner.hide()
        }
        
        SwiftSpinner.show("Fetching Shipping Details...")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let numTableSections = numTableSections {
            return numTableSections
        }
        
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Seller, Shipping Info, and/or Return Policy Exist
        guard let data = tableData else {
            return 0
        }
        
        // Use sectionNumber counter to determine which section belongs to whom
        // and use this information to return proper row count for section
        var sectionNumber = -1
        if data["Seller"] != nil && data["Seller"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                return data["Seller"]!.count
            }
        }
        if data["ShippingInfo"] != nil && data["ShippingInfo"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                return data["ShippingInfo"]!.count
            }
        }
        if data["ReturnPolicy"] != nil && data["ReturnPolicy"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                return data["ReturnPolicy"]!.count
            }
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Seller, Shipping Info, and/or Return Policy Exist
        guard let data = tableData else {
            return UIView()
        }
        
        // Configure generic design for section header
        var sectionNumber = -1
        if data["Seller"] != nil && data["Seller"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                let sectionHeader = ShippingTableSectionHeaderView()
                sectionHeader.title.text = "Seller"
                sectionHeader.icon.image = UIImage(named: "Seller")
                return sectionHeader
            }
        }
        if data["ShippingInfo"] != nil && data["ShippingInfo"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                let sectionHeader = ShippingTableSectionHeaderView()
                sectionHeader.title.text = "Shipping Info"
                sectionHeader.icon.image = UIImage(named: "Shipping Info")
                return sectionHeader
            }
        }
        if data["ReturnPolicy"] != nil && data["ReturnPolicy"]!.count != 0 {
            sectionNumber += 1
            
            if section == sectionNumber {
                let sectionHeader = ShippingTableSectionHeaderView()
                sectionHeader.title.text = "Return Policy"
                sectionHeader.icon.image = UIImage(named: "Return Policy")
                return sectionHeader
            }
        }
        
        return UIView()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "shippingCell", for: indexPath) as! ShippingTableViewCell
        
        // make sure itemDetails is populated
        guard let details = itemDetails else {
            return cell
        }
        
        var keyvalArr:[String] = []
        
        var sectionNum = -1
        guard let data = tableData else {
            return UITableViewCell()
        }
        if (data["Seller"] != nil) {
            sectionNum += 1
            
            if sectionNum == indexPath.section {
                keyvalArr = data["Seller"]![indexPath.row].components(separatedBy: ":")
            }
        }
        if (data["ShippingInfo"] != nil) {
            sectionNum += 1
            
            if sectionNum == indexPath.section {
                keyvalArr = data["ShippingInfo"]![indexPath.row].components(separatedBy: ":")
            }
        }
        if (data["ReturnPolicy"] != nil) {
            sectionNum += 1
            
            if sectionNum == indexPath.section {
                keyvalArr = data["ReturnPolicy"]![indexPath.row].components(separatedBy: ":")
            }
        }
        
        // Configure the cell...
        cell.col1.text = keyvalArr[0]
        
        if keyvalArr[0] == "Store Name" {
            if let storeURL = details["Store"]["URL"].string {
                let range = NSRange(location: 0, length: keyvalArr[1].count)
                let attributed = NSMutableAttributedString(string: keyvalArr[1])
                
                // linkify
                attributed.addAttribute(.link, value: storeURL, range: range)
                
                // adjust font size
                attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 16.0), range: range)
                
                // center text
                let centeredText = NSMutableParagraphStyle()
                centeredText.alignment = .center
                attributed.addAttribute(.paragraphStyle, value: centeredText, range: range)
                
                cell.col2.attributedText = attributed
                
                cell.col2.linkTextAttributes = [
                    NSAttributedString.Key.foregroundColor: UIColor(red: 31.0/255.0, green: 29.0/255.0, blue: 183.0/255.0, alpha: 1.0),
                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                ]
            }
        } else if keyvalArr[0] == "Feedback Star" { // Handle special case for feedback star
            var substring = ""
            var star: UIImage?
            if let range = keyvalArr[1].range(of: "Shooting") {
                let str = keyvalArr[1]
                substring = String(str[..<range.lowerBound])
                star = UIImage(named: "star")
            } else {
                substring = keyvalArr[1]
                star = UIImage(named: "starBorder")
            }
            let starView = UIImageView(image: star)
            starView.image = starView.image?.withRenderingMode(.alwaysTemplate)
            starView.tintColor = stringToUIColor(substring)
            starView.center = CGPoint(x: cell.col2.frame.size.width / 2, y: cell.col2.frame.size.height / 2)
            cell.col2.addSubview(starView)
        } else {
            cell.col2.text = keyvalArr[1]
        }
        
        return cell
    }
}

// MARK: Helper Methods
extension ShippingTableViewController {
    func setupTableData() -> [String:[String]]? {
        guard let details = itemDetails else {
            return nil
        }
        
        var data: [String:[String]] = [:]
        
        // Seller
        data["Seller"] = []
        if let storeName = details["Store"]["Name"].string {
            data["Seller"]!.append("Store Name:\(storeName)")
        }
        if let feedbackScore = details["Seller"]["Score"].int {
            data["Seller"]!.append("Feedback Score:\(feedbackScore)")
        }
        if let popularity = details["Seller"]["Popularity"].float {
            data["Seller"]!.append("Popularity:\(popularity)")
        }
        if let feedbackStar = details["Seller"]["Rating"].string {
            data["Seller"]!.append("Feedback Star:\(feedbackStar)")
        }
        
        // Shipping Info
        data["ShippingInfo"] = []
        if let shippingCost = details["Shipping"]["Cost"].string {
            data["ShippingInfo"]!.append("Shipping Cost:\(shippingCost)")
        }
        if let globalShipping = details["Shipping"]["GlobalShipping"].string {
            data["ShippingInfo"]!.append("Global Shipping:\(globalShipping)")
        }
        if let handlingTime = details["Shipping"]["HandlingTime"].string {
            data["ShippingInfo"]!.append("Handling Time:\(handlingTime)")
        }
        
        // Return Policy
        data["ReturnPolicy"] = []
        if let policy = details["ReturnPolicyType"].string {
            data["ReturnPolicy"]!.append("Policy:\(policy)")
        }
        if let refundMode = details["ReturnPolicyRefund"].string {
            data["ReturnPolicy"]!.append("Refund Mode:\(refundMode)")
        }
        if let returnWithin = details["ReturnPolicyDays"].string {
            data["ReturnPolicy"]!.append("Refund Within:\(returnWithin)")
        }
        if let shippingCostPaidBy = details["ReturnPolicyShippingCostPaidBy"].string {
            data["ReturnPolicy"]!.append("Shipping Cost Paid By:\(shippingCostPaidBy)")
        }
        
        return data
    }
    
    func stringToUIColor(_ string:String) -> UIColor? {
        switch(string) {
            case "Yellow":
                return UIColor.orange
            case "Blue":
                return UIColor.blue
            case "Turquoise":
                return UIColor(red: 21.0/255.0, green: 205.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            case "Purple":
                return UIColor.purple
            case "Red":
                return UIColor.red
            case "Green":
                return UIColor.green
            default:
                print("Should never run")
                return nil
            }
    }
}
