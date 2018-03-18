//
//  SuggestionHeaderView.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/17/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

class SuggestionHeaderView: UIView {

    let label : UILabel
    let view : UIView
    
    override init(frame: CGRect)  {
        label = UILabel(frame: .zero)
        view = UIView(frame: .zero)
        super.init(frame:frame)
        addSubview(view)
        view.addSubview(label)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        label = UILabel(frame: .zero)
        view = UIView(frame: .zero)
        super.init(coder: aDecoder)
        addSubview(view)
        view.addSubview(label)
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(red: 0, green: 0.73, blue: 1.0, alpha: 0.5)
        backgroundColor = UIColor.clear
        
        view.frame =  CGRect(x: 0, y: 0, width: 160, height: 24)
        label.frame = CGRect(x: 16, y: 0, width: 160, height: 24)
        
        view.layer.cornerRadius =  8.0
    }
}
