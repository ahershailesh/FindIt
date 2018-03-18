//
//  SuggestionTableViewCell.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/17/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

enum LabelState {
    case normal
}

class SuggestionTableViewCell: UITableViewCell {

    //@IBOutlet weak var labelBackground: UIView!
    
    @IBOutlet weak var labelViewBackground: UIView!
    @IBOutlet weak var label: UILabel!
    var state : LabelState = .normal
    
    var suggesion : Suggestion? {
        didSet {
            label.text = suggesion?.title
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    private func setupCell() {
        selectionStyle = .none
        switch state {
        case .normal:
            labelViewBackground.backgroundColor = UIColor(named: "darkBlue")
            label.textColor = UIColor.white
            labelViewBackground.layer.cornerRadius = 16.0
            contentView.backgroundColor = UIColor.clear
            backgroundColor = UIColor.clear
        }
    }
}
