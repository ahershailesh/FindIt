//
//  ImageViewCollectionViewCell.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/5/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import Kingfisher

class ImageViewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 8
    }

    var photoModel : PhotoModel? {
        didSet {
            if let imageUrl = photoModel?.getUrlString(), let url = URL(string: imageUrl) {
                imageView.kf.setImage(with: url)
            }
        }
    }
}
