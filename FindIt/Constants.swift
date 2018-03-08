//
//  Constants.swift
//  VirtualTourist
//
//  Created by Shailesh Aher on 1/28/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import AVFoundation

//MARK:- Constant values
class Constants: NSObject {
    
    static let FlickrKey = "514a7e6e18b0b4d9ce2b42e211d9dbb6"
    static let FlickrSecret = "350868e251fca8b6"
    static let Url = "https://api.flickr.com"
    
    //MARK: Block
    typealias CompletionBlock = ((Bool,Any?,Error?) -> Void)
    typealias VoidBlock = (() -> Void)
    
    //MARK:- Enums
    //MARK:-
    enum ErrorCode : String {
        //Login
        case LoginFailed = "Login failed"
        
        //Network
        case Network = "No network available"
        
        //Server
        case ServerNotFound = "Server not found"
        
        //Default
        case None = "unable to reach server"
    }
    
    enum Color : Int {
        
        case LAVENDER, SUNGLO, HONEY_FLOWER, SHERPA_BLUE, PICTON_BLUE, MADISON, FOUNTAIN_BLUE, JACKSONS_PURPLE, MEDIUM_TURQUOISE, SUMMER_GREEN, SALEM
        
        func getString() -> String {
            switch self {
            case .LAVENDER : return "947CB0"
            case .SUNGLO  : return "E26A6A"
            case .HONEY_FLOWER  : return  "674172"
            case .SHERPA_BLUE  : return  "013243"
            case .PICTON_BLUE  : return  "59ABE3"
            case .MADISON  : return  "2C3E50"
            case .FOUNTAIN_BLUE  : return  "5C97BF"
            case .JACKSONS_PURPLE  : return  "1F3A93"
            case .MEDIUM_TURQUOISE  : return  "4ECDC4"
            case .SUMMER_GREEN  : return  "91B496"
            case .SALEM  : return  "1E824C"
            }
        }
        
        static func getRandomColor() -> UIColor {
            let randomNumber = Int(arc4random() % 11)
            return UIColor(hex: Color(rawValue: randomNumber)!.getString())
        }
    }
    
    class func hasCameraAccess() -> Bool {
        let mediaType = AVMediaType.video
        let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        
        switch authStatus {
        case .authorized:
            return true
        case .denied:
            appDelegate.window?.rootViewController?.showAlert(message: "We are not authorised to use camera, please allow us to use camera from settings")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                
            }
        case .restricted:
            appDelegate.window?.rootViewController?.showAlert(message: "Camera functionality is not available", title: "Improtant")
        }
        
        return authStatus == .authorized
    }
}

let appDelegate = UIApplication.shared.delegate as! AppDelegate

//MARK:- global function
func saveLog(_ content : Any) {
    print(content)
}

func mainThread(block : Constants.VoidBlock?) {
    if Thread.isMainThread {
        block?()
    } else {
        DispatchQueue.main.sync {
            block?()
        }
    }
}

func backgroundThread(block : Constants.VoidBlock?) {
    DispatchQueue.global(qos: .background).async {
        block?()
    }
}

