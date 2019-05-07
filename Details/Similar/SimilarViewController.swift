//
//  SimilarViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/13/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SwiftSpinner

class SimilarViewController: UIViewController {
    var similarItems: JSON?
    var sortedItemList: [JSON]!
    var imageDictionary: [String: UIImage] = [:]
    var itemID: String!
    
    @IBOutlet weak var sortByToggle: UISegmentedControl!
    @IBOutlet weak var orderToggle: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noResultsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        orderToggle.isUserInteractionEnabled = false
        
        // load merchandising details
        var params = [String: Any]()
        params["itemID"] = itemID
        let url = "\(Constants.SERVER_PATH)/merchandising"
        Alamofire.request(url, parameters: params).responseJSON { [weak self] response in
            guard let jsonString = response.result.value else {
                print("json string doesn't exist")
                return
            }
            let json = JSON(jsonString)
            self?.similarItems = json
            
            // If no similar items, show message and return
            if self?.similarItems!["items"].count == 0 {
                self?.noResultsView.isHidden = false
                SwiftSpinner.hide()
                return
            }
            
            self?.sortedItemList = self?.similarItems!["items"].arrayValue
            
            self?.collectionView.reloadData()
            
            SwiftSpinner.hide()
        }
        
        SwiftSpinner.show("Fetching Similar Items...")
    }
}

// MARK: IBActions
extension SimilarViewController {
    @IBAction func sortCollection(_ sender: UISegmentedControl) {
        guard let items = similarItems else {
            return
        }
        
        sortedItemList = sortedItems(items["items"].arrayValue)
        
        // If sort by not touched, reorder and return
        if sender == orderToggle {
            collectionView.reloadData()
            
            return
        }
        
        // Disable order toggle if user selected default
        if sortByToggle.selectedSegmentIndex == 0 {
            orderToggle.selectedSegmentIndex = 0
            orderToggle.isUserInteractionEnabled = false
        }
        
        // Enable if user switched
        if sortByToggle.selectedSegmentIndex != 0 && !orderToggle.isUserInteractionEnabled {
            orderToggle.isUserInteractionEnabled = true
        }
        
        collectionView.reloadData()
    }
}

// MARK: Delegate and DataSource funcs
extension SimilarViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        guard let items = similarItems else {
            return 0
        }
        
        return items["items"].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "similarCell", for: indexPath) as! SimilarCollectionViewCell
        
        // configure cell properties
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.cornerRadius = 7.5
        
        guard let sortedItemList = sortedItemList else {
            return cell
        }
        
        let item = sortedItemList[indexPath.row]
        
        // return num days or day if only 1 day left
        if let daysLeft = item["daysLeft"].string {
            let daysLeftEnding = (daysLeft == "1") ? "Day" : "Days"
            cell.daysLeft.text = "\(daysLeft) \(daysLeftEnding) Left"
        }
        
        cell.price.text = item["price"].string ?? ""
        cell.shippingPrice.text = item["shipping"].string ?? ""
        cell.title.text = item["title"].string ?? ""
        
        // Retrieve UIImage from dictionary or retrieve asynchronously if not stored
        let urlString = item["imageURL"].string ?? ""
        
        if imageDictionary[urlString] != nil {
            cell.image.image = imageDictionary[urlString]
        }
    
        let url = URL(string: urlString)
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!)
            if let data = data {
                DispatchQueue.main.async {
                    self.imageDictionary[urlString] = UIImage(data: data)
                    cell.image.contentMode = .scaleToFill
                    cell.image.image = self.imageDictionary[urlString]
                }
            }
        }
        
        // Configure cell tap
        cell.linkURL = item["url"].string ?? ""
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SimilarCollectionViewCell
        
        if let url = URL(string: cell.linkURL!) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: Helper functions
extension SimilarViewController {
    func sortedItems(_ items:[JSON]) -> [JSON] {
        switch sortByToggle.selectedSegmentIndex {
            case 0: // Default
                return items
            case 1: // Name
                return items.sorted(by: {
                    (orderToggle.selectedSegmentIndex == 0) ? $0["title"] < $1["title"] : $0["title"] > $1["title"]
                })
            case 2: // Price
                return items.sorted(by: sortByPrice)
            case 3: // Days Left
                return items.sorted(by: sortByDaysLeft)
            case 4: // Shipping
                return items.sorted(by: sortByShipping)
            default:
                return items
        }
    }
    
    func sortByPrice(_ el1:JSON, _ el2:JSON) -> Bool {
        if let priceAString = el1["price"].string, let priceBString = el2["price"].string {
            let priceA = Float(String(priceAString.dropFirst()))
            let priceB = Float(String(priceBString.dropFirst()))
            
            // Ascending / Descending respectively
            return (orderToggle.selectedSegmentIndex == 0) ? Bool(priceA! < priceB!) : Bool(priceA! > priceB!)
        }
        
        return false
    }
    
    func sortByShipping(_ el1:JSON, _ el2:JSON) -> Bool {
        if let shippingAString = el1["shipping"].string, let shippingBString = el2["shipping"].string {
            let shippingA = Float(String(shippingAString.dropFirst()))
            let shippingB = Float(String(shippingBString.dropFirst()))
            
            // Ascending / Descending respectively
            return (orderToggle.selectedSegmentIndex == 0) ? Bool(shippingA! < shippingB!) : Bool(shippingA! > shippingB!)
        }
        
        return false
    }
    
    func sortByDaysLeft(_ el1:JSON, _ el2:JSON) -> Bool {
        if let dayAString = el1["daysLeft"].string, let dayBString = el2["daysLeft"].string {
            let dayA = Int(dayAString)
            let dayB = Int(dayBString)
            
            // Ascending / Descending respectively
            return (orderToggle.selectedSegmentIndex == 0) ? Bool(dayA! < dayB!) : Bool(dayA! > dayB!)
        }
        
        return false
    }
}
