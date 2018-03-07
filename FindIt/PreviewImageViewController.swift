//
//  PreviewImageControllerViewController.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/6/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

protocol PreviewImageProtocol {
    func imageLikeButtonTapped(model: PreviewModel, selection: Bool)
    func imageShared(model: PreviewModel)
}

class PreviewImageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    var notifier : PreviewImageProtocol?
    
    var model : PreviewModel?
    var selection : Bool = false {
        didSet {
            setupToolBar()
        }
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolBar()
        imageView.image = model?.image
    }
    
    func setupToolBar() {
        navigationController?.setToolbarHidden(false, animated: true)
        let imageName = selection ? "hearts_24" : "heart_blank"
        let likeButton = UIBarButtonItem(image: UIImage(named: imageName), style: .plain, target: self, action: #selector(likeButtonTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped))
        setToolbarItems([likeButton, spacer, share], animated: true)
    }
    
    
    @objc func likeButtonTapped() {
        selection = !selection
        notifier?.imageLikeButtonTapped(model: model!, selection: selection)
    }
    
    @objc func shareButtonTapped() {
        let activityController = UIActivityViewController(activityItems: [model?.image!], applicationActivities: nil)
        activityController.completionWithItemsHandler = { [weak self] (_,completed,_, _) in
            if completed {
                self?.notifier?.imageShared(model: self!.model!)
            }
        }
        present(activityController, animated: true, completion: nil)
    }
}
