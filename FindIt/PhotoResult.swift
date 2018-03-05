//
//  PhotoResult.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/5/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

class PhotoResult: NSObject {
    @objc var page : Int = 0
    @objc var pages : Int = 0
    @objc var perpage : Int = 0
    @objc var total : String?
    @objc var photo : [PhotoModel]?
    @objc var stat : String?
    @objc var tags : [String]?
    
    func setPhoto(fromDictionary dictionary: [AnyHashable : Any]) {
        photo = [PhotoModel]()
        if let array = dictionary["photo"] as? [[String: Any]] {
            photo?.append(contentsOf: array.map({ (dict) -> PhotoModel in
                let photoModel = PhotoModel(dictionary: dict)
                return photoModel
            }))
        }
    }
}
