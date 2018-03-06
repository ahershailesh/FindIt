//
//  PhotoModel.swift
//  VirtualTourist
//
//  Created by Shailesh Aher on 2/3/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import Foundation

class PhotoModel : NSObject {
    @objc var id : String?
    @objc var owner : String?
    @objc var secret : String?
    @objc var server : String?
    @objc var farm : Int = 0
    @objc var title : String?
    
    func getUrlString() -> String {
        let imageName = id! + "_" + secret! + ".jpg"
        let url = "http://farm" + "\(farm)" + ".staticflickr.com/" + server! + "/" + imageName
        return url
    }
}
