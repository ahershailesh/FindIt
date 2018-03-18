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
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var previewView: UIView!
    
    private var suggestionHandler = SuggestionDataHandler()
    private var localSuggestions = [Suggestion]()
    private let reuseIdentifier = "SuggestionCell"
    private let suggestionController : SuggestionListController
    private var gesture : UIPanGestureRecognizer?
    private var swipeView = UIView(frame: .zero)
    
    enum SuggestionListStatus {
        case fullScreen, halfScreen, midWay
    }
    
    private var listStatus : SuggestionListStatus = .halfScreen
    
    // video capture session
    private let session = AVCaptureSession()
    // preview layer
    private var previewLayer: AVCaptureVideoPreviewLayer!
    // queue for processing video frames
    private let captureQueue = DispatchQueue(label: "captureQueue")
    // overlay layer
    private var gradientLayer: CAGradientLayer!
    // vision request
    private var visionRequests = [VNRequest]()
    
    private var recognitionThreshold : Float = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        suggestionController = SuggestionListController()
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        suggestionController = SuggestionListController()
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        navigationController?.hidesBarsOnSwipe = true
        
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.loadSuggestion), userInfo: nil, repeats: true)
        
        setupCameraView()
        setupSuggestionTableView()
    }
    
    private func setupSuggestionTableView() {
        suggestionHandler.callBack = self
        suggestionController.dataHandler = suggestionHandler
        suggestionController.view.frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
        
        let paddingView = UIView(frame: .zero)
        paddingView.frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.height/2)
        paddingView.backgroundColor = .clear
        suggestionController.tableView.tableHeaderView = paddingView
        addChildViewController(suggestionController)
        view.addSubview(suggestionController.view)
    }

    private func setupCameraView() {
        // get hold of the default video camera
        guard let camera = AVCaptureDevice.default(for: .video) else {
            showAlert(message: "Camera functionality is not available", title: "Improtant")
            navigationController?.popViewController(animated: true)
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
            previewView.layer.addSublayer(gradientLayer)
            
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView?.bounds ?? CGRect.zero
        gradientLayer?.frame = previewView?.bounds ?? CGRect.zero
        
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
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print(error)
        }
    }
    
    private func handleClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        localSuggestions = observations[0...4] // top 4 results
            .compactMap({ $0 as? VNClassificationObservation })
            .compactMap({$0.confidence > recognitionThreshold ? $0 : nil})
            .map({ Suggestion(title: $0.identifier, value: $0.confidence) })
    }
    
    @objc private func loadSuggestion() {
        suggestionHandler.addSuggestions(suggestions: localSuggestions)
    }
}

extension CameraController : SuggestionCallBacks {
    func shouldShowHeader(forPage page: Int) -> Bool {
        return page == 0 ? false : true
    }
    
    func shouldSelect(suggestion: Suggestion, indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableViewScrolled(scrollView: UIScrollView)
    }
}

extension CameraController : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
