//
//  ResultsTableViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/7/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftSpinner
import SwiftyJSON
import Toast_Swift
import Alamofire

class ResultsTableViewController: UITableViewController {
    // both values are guaranteed to exist
    var results: JSON!
    var resultsArray: [JSON]!
    var searchViewController: ViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Check for error
        resultsArray = results["results"].arrayValue
        
        // show no results and return to previous controller
        if (resultsArray.count == 0) {
            let noResultsAlert = UIAlertController(title: "No Results!", message: "Failed to fetch search results", preferredStyle: .alert)
            noResultsAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] (action) in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(noResultsAlert, animated: true)
        }
        
        searchViewController = self.navigationController?.viewControllers.first as? ViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
}

// MARK: Table View Delegate Actions
extension ResultsTableViewController {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArray.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultsCell", for: indexPath) as! ResultsTableViewCell
        
        // Configure the cell
        let result = resultsArray[indexPath.row]
        cell.delegate = self
        cell.data = result
        
        // Set wishlist button if item in wishlist
        if UserDefaults.standard.string(forKey: result["id"].stringValue) != nil {
            cell.itemWishListStatus.setBackgroundImage(UIImage(named: "wishListFilled"), for: .normal)
        } else {
            cell.itemWishListStatus.setBackgroundImage(UIImage(named: "wishListEmpty"), for: .normal)
        }
        
        // Configure image and fetch asynchronously
        DispatchQueue.global().async {
            if let url = URL(string:(result["image"].string ?? "")) {
                let data = try? Data(contentsOf: url)
                if let data = data {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ResultsTableViewCell
        
        //construct query
        guard let data = cell.data else {
            print("cell data doesn't exist")
            return
        }

        let detailsVC = self.storyboard?.instantiateViewController(withIdentifier: "detailsVC") as! DetailsTabBarController
        detailsVC.cellData = data
        self.navigationController?.pushViewController(detailsVC, animated: true)
    }
}

// MARK: Results Cell Delegate Actions
extension ResultsTableViewController: ResultsCellDelegate {    
    func wishListToggledOn(_ resultsCell: ResultsTableViewCell) {
        if let data = resultsCell.data {
            let defaults = UserDefaults.standard
            defaults.set(data.rawString(), forKey: data["id"].stringValue)
            searchViewController.wishListView.items.append(data["id"].stringValue)
            
            // add to total cost
            if let price = data["price"].string {
                let start = price.index(price.startIndex, offsetBy: 1)
                searchViewController.wishListView.totalCost += Float(String(price[start...])) ?? 0.0
            }
            
            self.view.superview!.makeToast("\(data["title"].stringValue) was added to the wishList", duration: 2.0)
        }
        
        searchViewController.wishListView.reloadWishList(withData: true)
    }
    
    func wishListToggledOff(_ resultsCell: ResultsTableViewCell) {
        guard let data = resultsCell.data else {
            return
        }
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: data["id"].stringValue)
        if let index = searchViewController.wishListView.items.index(of: data["id"].stringValue) {
            searchViewController.wishListView.items.remove(at: index)
            
            // remove from total cost
            if let price = data["price"].string {
                let start = price.index(price.startIndex, offsetBy: 1)
                searchViewController.wishListView.totalCost -= Float(String(price[start...])) ?? 0.0
            }
            
            self.view.superview!.makeToast("\(data["title"].stringValue) was removed from the wishList", duration: 2.0)
        }
        
        searchViewController.wishListView.reloadWishList(withData: true)
    }
}
