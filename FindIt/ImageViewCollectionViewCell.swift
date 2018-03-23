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
    
    @IBOutlet weak var selectedIndicatorImage: UIImageView!
    var selection : Bool? {
        didSet {
            guard let selection = selection else {
                return
            }
            setSelected(selection: selection)
        }
    }
    
    var like : Bool? {
        didSet {
            guard let selection = like else {
                return
            }
            setLiked(bool : selection)
        }
    }

    var photoModel : PhotoModel? {
        didSet {
            self.layer.cornerRadius = 8
            if let imageUrl = photoModel?.getUrlString(), let url = URL(string: imageUrl) {
                imageView.kf.setImage(with: url, placeholder: self, options: nil, progressBlock: nil, completionHandler: nil)
            }
        }
    }
    
    var savedModel : SavedImage? {
        didSet {
            guard let model = savedModel, let data = model.image else {
                return
            }
            self.layer.cornerRadius = 8
            imageView.image = UIImage(data: data as Data)
        }
    }
    
    private func setSelected(selection: Bool) {
        let image = selection ? UIImage(named: "checked") : nil
        selectedIndicatorImage.image = image
        self.selectedIndicatorImage.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.3) {
            self.selectedIndicatorImage.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        imageViewAnimation(forSelection: selection)
    }
    
    private func imageViewAnimation(forSelection selection: Bool) {
        var scale : CGFloat = 1
        if selection {
            scale = 0.8
        }
        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    private func setLiked(bool selection: Bool) {
        let image = selection ? UIImage(named: "hearts_24") : nil
        selectedIndicatorImage.image = image
        self.selectedIndicatorImage.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.3) {
            self.selectedIndicatorImage.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        imageViewAnimation(forSelection: selection)
    }
    
    func add(to imageView: ImageView) {
        imageView.image = UIImage(named: "no_image")
    }
    
    /// How the placeholder should be removed from a given image view.
    func remove(from imageView: ImageView) {
        imageView.image = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "no_image")
    }
}
