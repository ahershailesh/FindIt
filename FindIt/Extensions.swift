//
//  Extensions.swift
//  VirtualTourist
//
//  Created by Shailesh Aher on 1/28/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

extension NSObject {
    func map(dictionary: [String: Any]) {
        let keyArray = propertyNames()
        for key in keyArray {
            if let value = dictionary[key] {
                setValue(value, forKey: key)
            }
        }
    }
    
    private func propertyNames() -> [String] {
        return Mirror(reflecting: self).children.flatMap { $0.label }
    }
    
    convenience init(dictionary: [String: Any]) {
        self.init()
        map(dictionary: dictionary)
    }
}

extension UIViewController {
    
    func showAlert(message: String, title : String = "Important" ) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            controller.dismiss(animated: true, completion: nil)
        }
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }

    func show(error : Error?, title : String = "Error"){
        guard let error = error else {
            showAlert(message: "Something went wrong, please refresh page", title: "Error")
            return
        }
        showAlert(message: get(error).rawValue, title: "Error")
    }
    
    private func get(_ error : Error) -> Constants.ErrorCode{
        
        if let err = error as? URLError{
            switch err.code {
            case URLError.Code.notConnectedToInternet, URLError.Code.cannotConnectToHost:
                return Constants.ErrorCode.Network
                
            case URLError.Code.cannotFindHost:
                return Constants.ErrorCode.ServerNotFound
                
            default:
                return Constants.ErrorCode.None
            }
        }
        return Constants.ErrorCode.None
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}


extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

