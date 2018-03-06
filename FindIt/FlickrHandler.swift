//
//  FlickrHandler.swift
//  VirtualTourist
//
//  Created by Shailesh Aher on 1/28/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import CoreData

@objc protocol FlickrProtocol {
    @objc func prefetchingDone()
    @objc optional func prefetchingWillStart()
    @objc optional func selectedContentsEmptied()
}


class FlickrHandler: NetworkManager {
    
    var notifier : FlickrProtocol?
    var mode : ImageCollectionViewController.ImageCollectionViewMode
    
    private var photoResult : PhotoResult?
    private let offset = 10
    private var prefetchingStatus = false
    private var savedImages = [SavedImage]()
    private var savedImageIds = [String]()
    
    init(mode : ImageCollectionViewController.ImageCollectionViewMode) {
        self.mode = mode
        super.init()
        self.delegate = self
        setupSavedImageDataSource()
    }
    
    func getPhoto(withTags tags : String = "", page : String = "1", completionBlock: Constants.CompletionBlock?) {
        let queryParam = ["tags" : tags.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "", "page" : page, "method" : "flickr.photos.search"]
        
        get(queryParam: queryParam) { [weak self] (success, response, error) in
            var result : PhotoResult?
            if success, let dictionary = response as? [String : Any], let photos = dictionary["photos"] as? [String : Any] {
                result = PhotoResult(dictionary: photos)
                result?.setPhoto(fromDictionary: photos)
                result?.tags = [tags]
                self?.mergeResults(nextResult: result!)
            }
            completionBlock?(success, result , error)
        }
    }
    
    func getImageCount() -> Int {
        var imageCount = 0
        switch mode {
        case .newCollection:
            let count = (photoResult?.perpage ?? 0) * (photoResult?.page ?? 0)
            let totalString = photoResult?.total ?? ""
            let total = Int(totalString) ?? 0
            imageCount = count < total ? count : total
        case .savedCollection:
            imageCount = savedImages.count
        }
        return imageCount
    }
    
    func getData(atIndex index: Int) -> PhotoModel? {
        checkAndExecutePrefetching(forIndex: index)
        if index < getImageCount(), let item = photoResult?.photo?[index] {
            return item
        }
        return nil
    }
    
    func getSavedObject(atIndex index: Int) -> SavedImage? {
        if index < getImageCount() {
            return savedImages[index]
        }
        return nil
    }
    
    func selectImage(id: String, imageData: NSData, keyword: String) -> Bool {
        var status = false
        if let index = savedImageIds.index(of: id), index < savedImageIds.count {
            savedImageIds.remove(at: index)
            appDelegate.coreDataStack.context?.delete(savedImages[index])
            if savedImageIds.isEmpty {
                notifier?.selectedContentsEmptied?()
            }
            status = false
            
        } else {
            if mode != .savedCollection {
                let savedImage = SavedImage(tag: keyword, pic: imageData, id: id, contenxt: appDelegate.coreDataStack.context!)
                savedImages.append(savedImage)
            }
            savedImageIds.append(id)
            status = true
        }
        return status
    }
    
    func isImageSelected(id: String) -> Bool {
        return savedImageIds.contains(id)
    }
    
    private func mergeResults(nextResult: PhotoResult) {
        guard let prevResult = photoResult else {
            photoResult = nextResult
            return
        }
        prevResult.page = nextResult.page
        prevResult.photo?.append(contentsOf: nextResult.photo ?? [])
        notifier?.prefetchingDone()
    }
    
    private func checkAndExecutePrefetching(forIndex index: Int) {
        if index == (getImageCount() - offset) && !prefetchingStatus {
            notifier?.prefetchingWillStart?()
            prefetchingStatus = false
            prefFetchData()
        }
    }
    
    private func prefFetchData() {
        if let result = photoResult, let tags = result.tags, result.page != result.pages {
            getPhoto(withTags: tags[0], page: "\(result.page + 1)" , completionBlock: nil)
        }
    }
    
    
    //MARK:- Saved Images Functionality -
    private func setupSavedImageDataSource() {
        savedImages = getSavedImages()
        if mode == .newCollection {
            savedImageIds = savedImages.flatMap { $0.id }
        }
    }
    
    private func getSavedImages() -> [SavedImage] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedImage")
        var savedImages = [SavedImage]()
        if let objectArray = try? appDelegate.coreDataStack.context?.fetch(request) as? [SavedImage] {
            savedImages = objectArray ?? []
        }
        return savedImages
    }
    
    func refreshSavedData() {
        setupSavedImageDataSource()
    }
    
    func deleteSelectedImages() {
        let selectedImages = savedImages.filter { (savedImage) -> Bool in
            if let id = savedImage.id {
                return savedImageIds.contains(id)
            }
            return false
        }
        for image in selectedImages {
            appDelegate.coreDataStack.context?.delete(image)
        }
        savedImageIds.removeAll()
        setupSavedImageDataSource()
    }
}

extension FlickrHandler : NetworkProtocol {
    
    func getUrl() -> String {
        return Constants.Url
    }
    
    func compulsoryPathParam() -> [String] {
        return ["services", "rest"]
    }
    
    func compulsoryQueryParam() -> [String : String] {
        return ["api_key" : Constants.FlickrKey,
                "format" : "json",
                "nojsoncallback" : "1"]
    }
}
