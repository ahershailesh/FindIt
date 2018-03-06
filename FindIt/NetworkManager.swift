//
//  NetworkManager.swift
//  VirtualTourist
//
//  Created by Shailesh Aher on 1/28/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import Foundation

@objc protocol NetworkProtocol {
    @objc optional func getUrl() -> String
    @objc optional func compulsoryPathParam() -> [String]
    @objc optional func compulsoryQueryParam() -> [String : String]
    @objc optional func compulsoryHeaders() -> [String : String]
}

class NetworkManager: NSObject {
    
    var delegate : NetworkProtocol?
    
    func get(url: String? = nil, pathParam: [String]? = nil, queryParam: [String: String]? = nil, headers: [String: String]? = nil, completionBlock: Constants.CompletionBlock?) {
        
        var url = url ?? delegate?.getUrl?() ?? ""
        
        if let compulsoryPathParam = delegate?.compulsoryPathParam?(), !compulsoryPathParam.isEmpty {
            url = url + "/" + compulsoryPathParam.joined(separator: "/")
        }
        
        if let pathParameter = pathParam, !pathParameter.isEmpty  {
            url = url + "/" + pathParameter.joined(separator: "/")
        }
        
        var separator = "?"
        if let compulsoryQueryParam = delegate?.compulsoryQueryParam?(), !compulsoryQueryParam.isEmpty {
            separator = "&"
            url = url + "?" + compulsoryQueryParam.map { (key, value) -> String in
                return key + "=" + value
                }.joined(separator: "&")
        }
        
        if let queryParameter = queryParam, !queryParameter.isEmpty {
            url = url + separator + queryParameter.map { (key, value) -> String in
                return key + "=" + value
                }.joined(separator: "&")
        }
        
        saveLog(url)
        if let thisUrl = URL(string: url) {
            var request = URLRequest(url: thisUrl)
            request.httpMethod = "GET"
            addHeaders(request: &request, headers: headers)
            let urlSession = URLSession.shared
            let task = urlSession.dataTask(with: request, completionHandler: { [weak self]  (data, response, error) in
                let success =  error == nil
                var json : [String: Any]?
                if success {
                    do {
                    json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                        saveLog(json)
                    } catch {
                        saveLog("got error url = " + url)
                    }
                } else {
                    self?.showError(error: error)
                    saveLog(error)
                }
                completionBlock?(success, json, error)
            })
            saveLog("\(request.httpMethod!) - \(request.url!)")
            task.resume()
        } else {
            completionBlock?(false, nil, nil)
        }
    }
    
    func getData(urlString: String, completionBlock: Constants.CompletionBlock?) {
        saveLog("Downloading image from url = "+urlString)
        if let url = URL(string: urlString) {
            let data = NSData(contentsOf: url)
            completionBlock?(true, data, nil)
        }
    }
    
    func getWebPage(urlString: String, completionBlock: Constants.CompletionBlock?) {
        if let thisUrl = URL(string: urlString) {
            let urlSession = URLSession.shared
            let task = urlSession.dataTask(with: thisUrl, completionHandler: { (data, response, error) in
                let success =  error == nil
                var output = ""
                if success, let thisData = data {
                    output = String(bytes: thisData, encoding: .utf8) ?? ""
                } else {
                    saveLog(error)
                }
                completionBlock?(success, output, error)
            })
            task.resume()
        }
    }
    
    private func addHeaders(request : inout URLRequest, headers: [String: String]?) {
        if let compulsoryHeaders = delegate?.compulsoryHeaders?() {
            compulsoryHeaders.forEach({ (key, value) in
                request.setValue(value, forHTTPHeaderField: key)
            })
        }
        
        headers?.forEach({ (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        })
       
    }
    
    func post(url: String? = nil, pathParam: [String]? = nil, queryParam: [String: String]? = nil, headers: [String: String]? = nil, bodyString : String? = nil, completionBlock: Constants.CompletionBlock?) {
        
        var url = url ?? delegate?.getUrl?() ?? ""
        
        if let compulsoryPathParam = delegate?.compulsoryPathParam?(), !compulsoryPathParam.isEmpty {
            url = url + "/" + compulsoryPathParam.joined(separator: "/")
        }
        
        if let pathParameter = pathParam, !pathParameter.isEmpty  {
            url = url + "/" + pathParameter.joined(separator: "/")
        }
        
        var separator = "?"
        if let compulsoryQueryParam = delegate?.compulsoryQueryParam?(), !compulsoryQueryParam.isEmpty {
            separator = "&"
            url = url + "?" + compulsoryQueryParam.map { (key, value) -> String in
                return key + "=" + value
                }.joined(separator: "&")
        }
        
        if let queryParameter = queryParam, !queryParameter.isEmpty {
            url = url + separator + queryParameter.map { (key, value) -> String in
                return key + "=" + value
                }.joined(separator: "&")
        }
        
        if let thisUrl = URL(string: url) {
            var request = URLRequest(url: thisUrl)
            request.httpMethod = "POST"
            if let body = bodyString {
                request.httpBody = body.data(using: .utf8)
            }
            addHeaders(request: &request, headers: headers)
            let urlSession = URLSession.shared
            let task = urlSession.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                let success =  error == nil
                var json : [String: Any]?
                if success {
                    do {
                        json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                    } catch {
                        saveLog("got error while parsing json from url = " + url)
                    }
                } else {
                    self?.showError(error: error)
                    saveLog(error)
                }
                if let json = json {
                    saveLog(json)
                    completionBlock?(success, json, error)
                } else if let data = data {
                    let stringData = String(bytes: data, encoding: .utf8)
                    saveLog(stringData)
                    completionBlock?(success, stringData, error)
                } else {
                    completionBlock?(false, nil, error)
                }
            })
            saveLog("\(request.httpMethod!) - \(request.url!)")
            task.resume()
        }
    }
    
    private func showError(error : Error?) {
        appDelegate.window?.rootViewController?.show(error: error)
    }
    
}
