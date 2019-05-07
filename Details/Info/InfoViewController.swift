//
//  InfoViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/11/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import Alamofire

class InfoViewController: UIViewController {
    var itemID: String!
    var itemDetails: JSON?
    
    @IBOutlet weak var carousel: UIScrollView!
    @IBOutlet weak var carouselPagination: UIPageControl!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var itemDetailTable: UITableView!
    @IBOutlet weak var descriptionIcon: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.delegate = self
        
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
            
            self?.setupCarousel()
            
            // Table
            self?.itemDetailTable.delegate = self
            self?.itemDetailTable.dataSource = self
            self?.itemDetailTable.reloadData()
            
            SwiftSpinner.hide()
        }
        
        SwiftSpinner.show("Fetching Product Details...")
    }

    // Load Images asynchronously followed by a callback to pass images to carousel
    func loadImages(completion: @escaping (_ images: [UIImage]) -> Void) {
        guard let details = itemDetails else {
            return
        }
        
        let imageArray = details["Images"].array
        var imagesForCarousel:[UIImage] = []
        guard let images = imageArray else {
            completion([])
            return
        }
        
        DispatchQueue.global().async {
            for image in images {
                guard let url = URL(string:(image.string ?? "")) else {
                    if let image = UIImage(named: "default") {
                        imagesForCarousel.append(image)
                    }
                    continue
                }
                
                guard let data = try? Data(contentsOf: url) else {
                    return
                }
                imagesForCarousel.append(UIImage(data: data)!)
            }
            
            DispatchQueue.main.async {
                completion(imagesForCarousel)
            }
        }
    }
}

// MARK: Helper methods
extension InfoViewController {
    func setupCarousel() {
        guard let details = itemDetails else {
            return
        }
        
        loadImages(completion: { [weak self] (images) in
            self!.carousel.contentSize = CGSize(width: self!.carousel.frame.width * CGFloat(images.count), height: self!.carousel.frame.height)
            self!.carousel.isPagingEnabled = true
            self!.carousel.showsHorizontalScrollIndicator = false
            
            for ii in 0 ..< images.count {
                let imageView = UIImageView(image: images[ii])
                imageView.frame = CGRect(x: self!.carousel.frame.width * CGFloat(ii), y: 0, width: self!.carousel.frame.width, height: self!.carousel.frame.height)
                self!.carousel.addSubview(imageView)
            }
            
            self!.carouselPagination.numberOfPages = images.count
            self!.carouselPagination.currentPage = 0
        })
        
        itemTitle.text = details["Title"].stringValue
        itemTitle.numberOfLines = 3
        if let price = details["Price"].string {
            itemPrice.text = price
        } else {
            itemPrice.text = "N/A"
        }
        
        // Table
        itemDetailTable.delegate = self
        itemDetailTable.dataSource = self
    }
}

// MARK: ScrollView delegate methods
extension InfoViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndex = round(carousel.contentOffset.x/carousel.frame.width)
        carouselPagination.currentPage = Int(currentIndex)
    }
}

// MARK: TableView delegate methods
extension InfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let details = itemDetails else {
            print("itemDetails don't exist")
            return 0
        }
        
        if let itemDetailData = details["Other"].array {
            if itemDetailData.count == 0 {
                itemDetailTable.isHidden = true
                descriptionIcon.isHidden = true
                descriptionLabel.isHidden = true
            }
            return itemDetailData.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell") as! InfoTableViewCell
        
        guard let details = itemDetails else {
            print("itemDetails don't exist")
            return cell
        }
        
        if let itemDetailData = details["Other"].array {
            cell.col1.text = itemDetailData[indexPath.row]["Name"].stringValue
            
            // From specs: If multiple values for field, display only one
            let value = itemDetailData[indexPath.row]["Value"].stringValue
            cell.col2.text = value.components(separatedBy: ",")[0]
            
            return cell
        } else {
            itemDetailTable.isHidden = true
            descriptionIcon.isHidden = true
            descriptionLabel.isHidden = true
        }
        
        return UITableViewCell()
    }
    
    
}
