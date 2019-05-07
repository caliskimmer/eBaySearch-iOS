//
//  DetailsTabBarController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/11/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftSpinner

class DetailsTabBarController: UITabBarController {
    var merchData: JSON!
    
    // required for wishList cell reconstruction
    var cellData: JSON!
    
    var wishListButton: UIBarButtonItem?
    var shareButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let infoVC = self.viewControllers![0] as! InfoViewController
        let shippingVC = self.viewControllers![1] as! ShippingTableViewController
        let photosVC = self.viewControllers![2] as! PhotosViewController
        let similarVC = self.viewControllers![3] as! SimilarViewController
        infoVC.itemID = cellData["id"].stringValue
        shippingVC.itemID = cellData["id"].stringValue
        photosVC.itemTitle = cellData["title"].stringValue
        similarVC.itemID = cellData["id"].stringValue
        
        // bar button item initialization
        let exists = (UserDefaults.standard.object(forKey: cellData["id"].stringValue) != nil)
        let wishListImage = exists ? UIImage(named: "wishListFilled") : UIImage(named: "wishListEmpty")
        wishListButton = UIBarButtonItem(image: wishListImage, style: .plain, target: self, action: #selector(wishListTapped))
        shareButton = UIBarButtonItem(image: UIImage(named:"facebook"), style: .plain, target: self, action: #selector(shareTapped))
        navigationItem.rightBarButtonItems = [wishListButton!, shareButton!]
    }
    
    @objc func wishListTapped(sender: Any?) {
        let searchViewController = self.navigationController?.viewControllers.first as? ViewController
        
        // toggled on
        if wishListButton?.image == UIImage(named: "wishListEmpty") {
            wishListButton?.image = UIImage(named: "wishListFilled")
            
            let defaults = UserDefaults.standard
            defaults.set(cellData.rawString(), forKey: cellData["id"].stringValue)
            searchViewController?.wishListView.items.append(cellData["id"].stringValue)
            
            // add to total cost
            if let price = cellData["price"].string {
                let start = price.index(price.startIndex, offsetBy: 1)
                searchViewController?.wishListView.totalCost += Float(String(price[start...])) ?? 0.0
            }
            
            self.view.superview!.makeToast("\(cellData["title"].stringValue) was added to the wishList", duration: 2.0)
        } else { // toggled off
            wishListButton?.image = UIImage(named: "wishListEmpty")

            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: cellData["id"].stringValue)
            if let index = searchViewController?.wishListView.items.index(of: cellData["id"].stringValue) {
                searchViewController?.wishListView.items.remove(at: index)
                
                // remove from total cost
                if let price = cellData["price"].string {
                    let start = price.index(price.startIndex, offsetBy: 1)
                    searchViewController?.wishListView.totalCost -= Float(String(price[start...])) ?? 0.0
                }
                
                self.view.superview!.makeToast("\(cellData["title"].stringValue) was removed from the wishList", duration: 2.0)
            }
        }
        
        searchViewController?.wishListView.reloadWishList(withData: true)
    }
    
    @objc func shareTapped(sender: Any?) {
        let quote = "Buy \(cellData["title"].stringValue) for \(cellData["price"]) from Ebay!"
        let href = cellData["url"].string ?? ""
        let escapedQuote = quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let escapedHref = href.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        if let url = URL(string: "https://www.facebook.com/dialog/share?app_id=\(Constants.FACEBOOK_API)&display=popup&href=\(escapedHref)&quote=\(escapedQuote)&hashtag=%23CSCI571Spring2019Ebay") {
            UIApplication.shared.open(url)
        }
    }
}
