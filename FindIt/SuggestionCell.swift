//
//  SuggestionCell.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/6/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

class SuggestionCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = UIColor.white
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel.text = nil
    }
    
}
