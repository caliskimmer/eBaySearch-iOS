//
//  ViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/4/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import McPicker
import Toast_Swift
import Alamofire
import SwiftyJSON
import SwiftSpinner

@IBDesignable
class ViewController: UIViewController {
    let dropdownData = [["All",
                        "Art",
                        "Baby",
                        "Books",
                        "Clothing, Shoes & Accessories",
                        "Computers/Tablets & Networking",
                        "Health & Beauty",
                        "Music",
                        "Video Games & Consoles"]]
    var zips: [String] = []
    var postal: String = ""
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var wishListView: WishListView!
    @IBOutlet weak var categoryDropdown: UITextField!
    @IBOutlet weak var keywordField: UITextField!
    @IBOutlet weak var newCheck: UIButton!
    @IBOutlet weak var usedCheck: UIButton!
    @IBOutlet weak var unspecifiedCheck: UIButton!
    @IBOutlet weak var pickupCheck: UIButton!
    @IBOutlet weak var freeCheck: UIButton!
    @IBOutlet weak var distance: UITextField!
    @IBOutlet weak var search: FormButton!
    @IBOutlet weak var clear: FormButton!
    @IBOutlet weak var searchToggle: UISegmentedControl!
    @IBOutlet weak var zipTableView: UITableView!
    @IBOutlet weak var zipField: UITextField!
    @IBOutlet weak var locSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // wishlist init
        wishListView.isHidden = true
        wishListView.delegate = self
        wishListView.setupItemTable()
        
        categoryDropdown.tintColor = UIColor.clear
        
        // prepare default state for custom location
        zipField.isHidden = true
        search.frame.origin.y -= 30
        clear.frame.origin.y -= 30
        
        // prepare autocomplete table
        zipTableView.register(UITableViewCell.self, forCellReuseIdentifier: "zipCell")
        zipTableView.delegate = self
        zipTableView.dataSource = self
        zipTableView.isHidden = true
        zipTableView.layer.borderColor = UIColor.darkGray.cgColor
        zipTableView.layer.borderWidth = 2.0
        zipTableView.layer.cornerRadius = 4.0
        
        // fetch current zip
        Alamofire.request("http://ip-api.com/json").responseJSON { [weak self] response in
            guard let jsonString = response.result.value else {
                return
            }
            let json = JSON(jsonString)
            self?.postal = json["zip"].stringValue
        }
    }
}

// MARK: IBActions
extension ViewController {
    @IBAction func clearForm(_ sender: UIButton) {
        // reset fields
        keywordField.text = ""
        categoryDropdown.text = "All"
        newCheck.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        usedCheck.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        unspecifiedCheck.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        pickupCheck.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        freeCheck.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        distance.text = ""
        
        // reset zip field state if necessary
        if (!zipField.isHidden) {
            zipField.text = ""
            useCustomLocation(locSwitch)
            locSwitch.setOn(false, animated: true)
        }
    }
    
    @IBAction func showDropdown(_ sender: UITextField) {
        McPicker.show(data: dropdownData) { [weak self] (selections: [Int: String]) -> Void in
            if let name = selections[0] {
                self?.categoryDropdown.text = name
                self?.categoryDropdown.resignFirstResponder()
            }
        }
    }
    
    @IBAction func markCheckbox(_ sender: UIButton) {
        if sender.currentBackgroundImage == UIImage(named: "unchecked") {
            sender.setBackgroundImage(UIImage(named: "checked"), for: .normal)
        } else {
            sender.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
        }
    }
    
    @IBAction func useCustomLocation(_ sender: UISwitch) {
        // hide/show zip and move elements up/down to compensate for space
        if sender.isOn && zipField.isHidden {
            zipField.isHidden = false
            search.frame.origin.y += 30
            clear.frame.origin.y += 30
        } else {
            zipField.isHidden = true
            search.frame.origin.y -= 30
            clear.frame.origin.y -= 30
        }
    }
    
    @IBAction func toggleView(_ sender: UISegmentedControl) {
        switch searchToggle.selectedSegmentIndex {
        case 0:
            searchView.isHidden = false
            wishListView.isHidden = true
            break
        case 1:
            searchView.isHidden = true
            wishListView.isHidden = false
            wishListView.reloadWishList(withData: true)
        default:
            break
        }
    }
    
    @IBAction func fetchZips(_ sender: UITextField) {
        // reload zip with new values on text field change
        if let currInput = sender.text {
            zips = []
            let baseURL = "http://api.geonames.org/postalCodeSearchJSON?"
            let url = "\(baseURL)postalcode_startsWith=\(currInput)&username=\(Constants.GEONAMES_USER)&country=US&maxRows=5"
            Alamofire.request(url).responseJSON { [weak self] response in
                guard let jsonString = response.result.value else {
                    return
                }
                let json = JSON(jsonString)
                let postalCodes = json["postalCodes"]
                for (_,code) in postalCodes {
                    self?.zips.append(code["postalCode"].stringValue)
                }
                
                // reload zip table
                if self?.zips.count == 0 {
                    self?.zipTableView.isHidden = true
                    return
                }
                self?.zipTableView.isHidden = false
                self?.zipTableView.reloadData()
            }
        }
    }
    
    @IBAction func search(_ sender: UIButton) {
        // validation
        if keywordField.text == "" {
            self.view.makeToast("Keyword is Mandatory")
            return
        }
        if keywordField.text!.range(of: #"^[ ]+$"#, options: .regularExpression) != nil {
            self.view.makeToast("Keyword is Incorrect")
            return
        }
        if !zipField.isHidden && zipField.text == "" {
            self.view.makeToast("Zipcode is Mandatory")
            return
        }
        if !zipField.isHidden && zipField.text!.range(of: #"^[0-9]{5}$"#, options: .regularExpression) == nil {
            self.view.makeToast("Zipcode is Incorrect")
            return
        }
        
        var params = [String: Any]()
        
        // construct query
        params["keyword"] = keywordField.text
        params["category"] = categoryDropdown.text
        if (newCheck.currentBackgroundImage == UIImage(named: "checked")) {
            params["conditionNew"] = true
        }
        if (usedCheck.currentBackgroundImage == UIImage(named: "checked")) {
            params["conditionUsed"] = true
        }
        if (unspecifiedCheck.currentBackgroundImage == UIImage(named: "checked")) {
            params["conditionUnspecified"] = true
        }
        if (pickupCheck.currentBackgroundImage == UIImage(named: "checked")) {
            params["localShipping"] = true
        }
        if (freeCheck.currentBackgroundImage == UIImage(named: "checked")) {
            params["freeShipping"] = true
        }
        if (!distance.text!.isEmpty) {
            params["distance"] = distance.text
        }
        if (zipField.text!.isEmpty) {
            params["postal"] = postal
        } else {
            params["postal"] = zipField.text
        }
        
        let url = "\(Constants.SERVER_PATH)/finding"
        Alamofire.request(url, parameters: params).responseJSON { [weak self] response in
            guard let jsonString = response.result.value else {
                return
            }
            let json = JSON(jsonString)
            let resultsVC = self?.storyboard?.instantiateViewController(withIdentifier: "resultsVC") as! ResultsTableViewController
            resultsVC.results = json
            self?.navigationController?.pushViewController(resultsVC, animated: true)
            SwiftSpinner.hide()
        }
        SwiftSpinner.show("Searching...")
    }
}

// MARK: zipTableView delegate methods
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let zipCell = zipTableView.dequeueReusableCell(withIdentifier: "zipCell") {
            zipCell.textLabel?.text = zips[indexPath.row]
            return zipCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        zipField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        tableView.deselectRow(at: indexPath, animated: true)
        zipTableView.isHidden = true
    }
}

// MARK: wishListTableViewCell delegate methods
extension ViewController: WishListViewDelegate {
    func requestedDetails(_ wishListView: WishListView, forData data: JSON) {
        let detailsVC = self.storyboard?.instantiateViewController(withIdentifier: "detailsVC") as! DetailsTabBarController
        detailsVC.cellData = data
        self.navigationController?.pushViewController(detailsVC, animated: true)
    }
}

