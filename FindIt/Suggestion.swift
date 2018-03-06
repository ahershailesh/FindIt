//
//  Suggestion.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/6/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import Vision

class Suggestion: NSObject {
    var title : String?
    var value : VNConfidence = 0
    
    init(title: String, value: VNConfidence) {
        super.init()
        self.title = title
        self.value = value
    }
}
