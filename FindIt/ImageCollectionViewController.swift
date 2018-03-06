//
//  ImageCollectionViewController.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/5/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit
import CoreData

class ImageCollectionViewController: UIViewController {
    
    enum ImageCollectionViewMode {
        case savedCollection, newCollection
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    private let numberOfSections = 1
    private let LINE_SPACING : CGFloat = 4
    private let ITEM_SPACING : CGFloat = 4
    private let LEFT_PADDING : CGFloat = 8
    private let RIGHT_PADDING : CGFloat = 8
    private let CELL_HEIGHT : CGFloat = 100
    private let numberOfItemsInRow = 3
    
    private var dataHandler : FlickrHandler?
    
    private let reuseId = "ImageViewCollectionViewCell"
    var enableEditFunctionality = true
    
    
    convenience init(keyWord: String) {
        self.init(nibName: nil, bundle: nil)
        dataHandler = FlickrHandler(mode: .newCollection)
        dataHandler?.getPhoto(withTags: keyWord) { (success, _, _) in
            mainThread {
                if success {
                    self.collectionView.reloadData()
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        title = keyWord
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        dataHandler = FlickrHandler(mode: .savedCollection)
        title = "Saved Images"
    }
    
    private func getSavedImages() -> [SavedImage] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedImage")
        var savedImages = [SavedImage]()
        if let objectArray = try? appDelegate.coreDataStack.context?.fetch(request) as? [SavedImage] {
            savedImages = objectArray ?? []
        }
        return savedImages
    }
    
    @objc func presentCamera() {
       let controller = CameraController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        dataHandler?.refreshSavedData()
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = getItemSize()
            layout.minimumInteritemSpacing = ITEM_SPACING
            layout.minimumLineSpacing = LINE_SPACING
        }
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: reuseId, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: reuseId)
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = getItemSize()
            layout.minimumInteritemSpacing = ITEM_SPACING
            layout.minimumLineSpacing = LINE_SPACING
        }
        if dataHandler!.mode == .savedCollection {
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteImages))
            navigationItem.leftBarButtonItem = deleteButton
            navigationItem.leftBarButtonItem?.isEnabled = false
            let cameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(presentCamera))
            navigationItem.rightBarButtonItem = cameraButton
        }
        dataHandler!.notifier = self
    }
    
    private func getItemSize() -> CGSize {
        let deviceWidth = UIScreen.main.bounds.width  - LEFT_PADDING - RIGHT_PADDING
        let itemWidth = (deviceWidth - ITEM_SPACING * CGFloat(numberOfItemsInRow - 1))/CGFloat(numberOfItemsInRow)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    @objc private func deleteImages() {
        dataHandler?.deleteSelectedImages()
        collectionView.reloadData()
        navigationItem.leftBarButtonItem?.isEnabled = false
    }
}

extension ImageCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataHandler!.getImageCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        if let thisCell = cell as? ImageViewCollectionViewCell {
            
            switch dataHandler!.mode {
            case .newCollection:
                if let model = dataHandler!.getData(atIndex: indexPath.row) {
                    thisCell.photoModel = model
                    setSelection(onCell: thisCell, selection: dataHandler!.isImageSelected(id: model.id!))
                }
            case .savedCollection:
                if let model = dataHandler!.getSavedObject(atIndex: indexPath.row) {
                    thisCell.savedModel = model
                    setSelection(onCell: thisCell, selection: dataHandler!.isImageSelected(id: model.id!))
                }
            }
            return thisCell
        }
        return cell
    }
}

extension ImageCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? ImageViewCollectionViewCell
        let id = cell?.photoModel?.id ?? cell?.savedModel?.id
        if let thisId = id,
            let image = cell?.imageView.image,
            let imageData = UIImagePNGRepresentation(image) {
            navigationItem.leftBarButtonItem?.isEnabled = true
            let status = dataHandler!.selectImage(id: thisId, imageData: imageData as NSData, keyword: title!)
            setSelection(onCell: cell, selection: status)
        }
    }
    
    private func setSelection(onCell cell: ImageViewCollectionViewCell?, selection: Bool) {
        switch dataHandler!.mode {
        case .newCollection:
            cell?.like = selection
        case .savedCollection:
            cell?.selection = selection
        }
    }
}

extension ImageCollectionViewController: FlickrProtocol {
    func prefetchingDone() {
        mainThread {
            self.collectionView.reloadData()
        }
    }
    
    func selectedContentsEmptied() {
        navigationItem.leftBarButtonItem?.isEnabled = false
    }
}
