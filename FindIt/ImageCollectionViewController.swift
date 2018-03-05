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
    private let numberOfItemsInRow = 2
    
    private let dataHandler = FlickrHandler()
    
    let reuseId = "ImageViewCollectionViewCell"
    
    convenience init(keyWord: String) {
        self.init(nibName: nil, bundle: nil)
    }
    
    override func awakeFromNib() {
        dataHandler.getPhoto(withTags: "phone") { (_, _, _) in
            mainThread {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: reuseId, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: reuseId)
        collectionView.dataSource = self
        collectionView.delegate = self
        dataHandler.notifier = self
    }
    
    private func getItemSize(indexPath: IndexPath) -> CGSize {
        let deviceWidth = UIScreen.main.bounds.width  - LEFT_PADDING - RIGHT_PADDING
        let itemWidth = (deviceWidth - ITEM_SPACING * CGFloat(numberOfItemsInRow - 1))/CGFloat(numberOfItemsInRow)
        return CGSize(width: itemWidth, height: CELL_HEIGHT)
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
        }
        return cell
    }
}

extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LINE_SPACING
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return ITEM_SPACING
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return getItemSize(indexPath: indexPath)
    }
}

extension ImageCollectionViewController: FlickrProtocol {
    func prefetchingDone() {
        collectionView.reloadData()
    }
}
