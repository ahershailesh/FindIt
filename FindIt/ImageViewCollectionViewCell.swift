//
//  ImageViewCollectionViewCell.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/5/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import Kingfisher

class ImageViewCollectionViewCell: UICollectionViewCell, Placeholder {

    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor.white
    }

    var photoModel : PhotoModel? {
        didSet {
            self.layer.cornerRadius = 8
            if let imageUrl = photoModel?.getUrlString(), let url = URL(string: imageUrl) {
                imageView.kf.setImage(with: url, placeholder: self, options: nil, progressBlock: nil, completionHandler: nil)
            }
        }
    }
    
    func add(to imageView: ImageView) {
        imageView.image = UIImage(named: "no_image")
    }
    
    /// How the placeholder should be removed from a given image view.
    func remove(from imageView: ImageView) {
        imageView.image = nil
    }
}
