//
//  CameraController.swift
//  VisionSample
//
//  Created by chris on 19/06/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // video capture session
    let session = AVCaptureSession()
    // preview layer
    var previewLayer: AVCaptureVideoPreviewLayer!
    // queue for processing video frames
    let captureQueue = DispatchQueue(label: "captureQueue")
    // overlay layer
    var gradientLayer: CAGradientLayer!
    // vision request
    var visionRequests = [VNRequest]()
    private var suggestionArray = [Suggestion]()
    private var localSuggestions = [Suggestion]()
    private let reuseIdentifier = "SuggestionCell"
    var recognitionThreshold : Float = 0
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var previewView: UIView!
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(UINib(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        setupCollectionView()
        navigationController?.navigationBar.isHidden = false
        
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.loadSuggestion), userInfo: nil, repeats: true)
        
        // get hold of the default video camera
        guard let camera = AVCaptureDevice.default(for: .video) else {
            showAlert(message: "Camera functionality is not available", title: "Improtant")
            return
        }
        do {
            // add the preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewView.layer.addSublayer(previewLayer)
            // add a slight gradient overlay so we can read the results easily
            gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor,
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor,
            ]
            gradientLayer.locations = [0.0, 0.3]
            self.previewView.layer.addSublayer(gradientLayer)
            
            // create the capture input and the video output
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            session.sessionPreset = .high
            
            // wire up the session
            session.addInput(cameraInput)
            session.addOutput(videoOutput)
            
            // make sure we are in portrait mode
            let conn = videoOutput.connection(with: .video)
            conn?.videoOrientation = .portrait
            
            // Start the session
            session.startRunning()
            
            // set up the vision model
            guard let resNet50Model = try? VNCoreMLModel(for: Resnet50().model) else {
                fatalError("Could not load model")
            }
            // set up the request using our vision model
            let classificationRequest = VNCoreMLRequest(model: resNet50Model, completionHandler: handleClassifications)
            classificationRequest.imageCropAndScaleOption = .centerCrop
            visionRequests = [classificationRequest]
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func setupCollectionView() {
        collectionView.register(UINib(nibName: "SuggestionCell", bundle: nil), forCellWithReuseIdentifier: "SuggestionCell")
        self.collectionView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
        setEstimatedSizeIfNeeded()
    }
    
    private func setEstimatedSizeIfNeeded() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let estimatedWidth : CGFloat = 30
            if flowLayout.estimatedItemSize.width != estimatedWidth {
                flowLayout.estimatedItemSize = CGSize(width: estimatedWidth,height: 30)
                flowLayout.invalidateLayout()
            }
        }
    }
    
    @objc private func reload() {
        setEstimatedSizeIfNeeded()
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = self.previewView.bounds;
        gradientLayer.frame = self.previewView.bounds;
        
        let orientation: UIDeviceOrientation = UIDevice.current.orientation;
        switch (orientation) {
        case .portrait:
            previewLayer?.connection?.videoOrientation = .portrait
        case .landscapeRight:
            previewLayer?.connection?.videoOrientation = .landscapeLeft
        case .landscapeLeft:
            previewLayer?.connection?.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            previewLayer?.connection?.videoOrientation = .portraitUpsideDown
        default:
            previewLayer?.connection?.videoOrientation = .portrait
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        connection.videoOrientation = .portrait
        
        var requestOptions:[VNImageOption: Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // for orientation see kCGImagePropertyOrientation
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: requestOptions)
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func handleClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        localSuggestions = observations[0...4] // top 4 results
            .flatMap({ $0 as? VNClassificationObservation })
            .flatMap({$0.confidence > recognitionThreshold ? $0 : nil})
            .map({ Suggestion(title: $0.identifier, value: $0.confidence) })
    }
    
    @objc private func loadSuggestion() {
        suggestionArray = localSuggestions
        DispatchQueue.main.async {
            self.reload()
        }
    }
}

// MARK:- UICollectionViewDataSource -
extension CameraController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestionArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? SuggestionCell, let title = suggestionArray[indexPath.row].title{
            cell.textLabel.text = title
            return cell
        }
        return UICollectionViewCell()
    }
}

extension CameraController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let keyWord = suggestionArray[indexPath.row].title {
            let controller = ImageCollectionViewController(keyWord: keyWord)
            navigationController?.pushViewController(controller, animated: true)
            
        }
    }
}

