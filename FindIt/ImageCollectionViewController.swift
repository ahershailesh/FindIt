//
//  ImageCollectionViewController.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/5/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

class ImageCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    private let numberOfSections = 1
    private let LINE_SPACING : CGFloat = 8
    private let ITEM_SPACING : CGFloat = 8
    private let LEFT_PADDING : CGFloat = 8
    private let RIGHT_PADDING : CGFloat = 8
    private let CELL_HEIGHT : CGFloat = 100
    private let numberOfItemsInRow = 3
    
    private let dataHandler = FlickrHandler()
    
    let reuseId = "ImageViewCollectionViewCell"
    
    convenience init(keyWord: String) {
        self.init(nibName: nil, bundle: nil)
        dataHandler.getPhoto(withTags: keyWord) { (success, _, _) in
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = true
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
        dataHandler.notifier = self
    }
    
    private func getItemSize() -> CGSize {
        let deviceWidth = UIScreen.main.bounds.width  - LEFT_PADDING - RIGHT_PADDING
        let itemWidth = (deviceWidth - ITEM_SPACING * CGFloat(numberOfItemsInRow - 1))/CGFloat(numberOfItemsInRow)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

extension ImageCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataHandler.getImageCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        if let thisCell = cell as? ImageViewCollectionViewCell {
            thisCell.photoModel = dataHandler.getData(atIndex: indexPath.row)
            thisCell.contentView.backgroundColor = UIColor.red
            return thisCell
        }
        return cell
    }
}

extension ImageCollectionViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return LINE_SPACING
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return ITEM_SPACING
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return getItemSize(indexPath: indexPath)
//    }
}

extension ImageCollectionViewController: FlickrProtocol {
    func prefetchingDone() {
        mainThread {
            self.collectionView.reloadData()
        }
    }
}
