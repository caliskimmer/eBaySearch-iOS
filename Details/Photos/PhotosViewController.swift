//
//  PhotosViewController.swift
//  csci571hw9
//
//  Created by Matas Empakeris on 4/13/19.
//  Copyright © 2019 MatasEmpakeris. All rights reserved.
//

import UIKit
import SwiftSpinner
import Alamofire
import SwiftyJSON

class PhotosViewController: UIViewController {
    var itemTitle: String!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var noResultsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch images asynchronously
        var params = [String: Any]()
        params["productTitle"] = itemTitle
        let url = "\(Constants.SERVER_PATH)/search"
        Alamofire.request(url, parameters: params).responseJSON { [weak self] response in
            guard let jsonString = response.result.value else {
                return
            }
            let json = JSON(jsonString)

            // if no images found, display message and return
            if json["images"].count == 0 {
                SwiftSpinner.hide()
                self?.noResultsView.isHidden = false
                return
            }
            
            let images = json["images"].arrayObject as! [String]
            
            // scrollview and image setup
            self!.loadImages(images, completion: { [weak self] (images) in
                self!.scrollView.contentSize = CGSize(width: self!.scrollView.frame.width, height: self!.scrollView.frame.width * CGFloat(images.count))
                
                for ii in 0 ..< images.count {
                    let imageView = UIImageView(image: images[ii])
                    let padding:CGFloat = 15.0
                    imageView.frame = CGRect(x: self!.scrollView.frame.minX+padding, y: self!.scrollView.frame.width*CGFloat(ii), width: self!.scrollView.frame.width-padding*2, height: self!.scrollView.frame.width)
                    self!.scrollView.addSubview(imageView)
                }
                SwiftSpinner.hide()
            })
        }
        SwiftSpinner.show("Fetching Google Images...")
    }
    
    // Load Images asynchronously followed by a callback to pass images to carousel
    func loadImages(_ images: [String], completion: @escaping (_ images: [UIImage]) -> Void) {
        var imagesForView:[UIImage] = []

        DispatchQueue.global().async {
            for image in images {
                let url = URL(string:image)
                guard let data = try? Data(contentsOf: url!) else {
                    if let image = UIImage(named: "default") {
                        imagesForView.append(image)
                    }
                    continue
                }
                imagesForView.append(UIImage(data: data)!)
            }
            
            DispatchQueue.main.async {
                completion(imagesForView)
            }
        }
    }
}
