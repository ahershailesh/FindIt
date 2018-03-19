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
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK:- Suggestion related stuff
    private var suggestionHandler = SuggestionDataHandler()
    private var localSuggestions = [Suggestion]()
    private let reuseIdentifier = "SuggestionCell"
    private let suggestionController : SuggestionListController
    private var gesture : UIPanGestureRecognizer?
    private var swipeView = UIView(frame: .zero)
    
    enum SuggestionListStatus {
        case fullScreen, halfScreen
    }
    
    private var listStatus : SuggestionListStatus = .halfScreen
    private var maxScrollHeight : CGFloat = 300.0
    private var buttonSize = CGSize(width: 48, height: 48)
    private var maxButtonX = UIScreen.main.bounds.width - 48 - 16
    private var leftFrame = CGRect(origin: CGPoint(x: 16, y: 32), size:  CGSize(width: 48, height: 48))
    private var rightFrame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width - 48 - 16, y: 32), size:  CGSize(width: 48, height: 48))
    
    
    // MARK:- Camera related stuff
    private let session = AVCaptureSession() // video capture session
    private var previewLayer: AVCaptureVideoPreviewLayer! // preview layer
    private let captureQueue = DispatchQueue(label: "captureQueue") // queue for processing video frames
    private var gradientLayer: CAGradientLayer! // overlay layer
    private var visionRequests = [VNRequest]()  // vision request
    private var recognitionThreshold : Float = 0
    
    
    // MARK:- Initialization
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
    
    // MARK:- View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.loadSuggestion), userInfo: nil, repeats: true)
        
        setupCameraView()
        setupSuggestionTableView()
        setupButtons()
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
    
    // MARK:- Private methods
    private func setupButtons() {
        backButton.layer.cornerRadius = backButton.frame.width/2
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    @objc func backButtonTapped() {
        self.backButton.imageView?.transform =  CGAffineTransform(rotationAngle: CGFloat.pi/2)
    }
    
    private func setupSuggestionTableView() {
        suggestionHandler.callBack = self
        suggestionController.dataHandler = suggestionHandler
        suggestionController.view.frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
        
        addChildViewController(suggestionController)
        view.insertSubview(suggestionController.view, belowSubview: backButton)
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
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor,
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
    
    internal func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
    
    private func changeUI(withCurrentScrollPosition position: CGFloat) {
        var percentShift : CGFloat = 0
        if position > 0 {
            percentShift = 1
            if position <= maxScrollHeight {
                percentShift = CGFloat(position / maxScrollHeight)
                let buttonX = CGFloat(maxButtonX - 16) * percentShift + 16
                UIView.animate(withDuration: 0.1, animations: {
                    self.backButton.frame = CGRect(origin: CGPoint(x: buttonX, y: 32), size: self.buttonSize)
                    let angle = percentShift * (CGFloat.pi/(-2))
                    self.backButton.transform =  CGAffineTransform(rotationAngle: angle)
                })
            } else {
                self.backButton.frame = rightFrame
                self.backButton.transform =  CGAffineTransform(rotationAngle: (-1)*CGFloat.pi/2)
            }
        } else {
            self.backButton.frame = leftFrame
            self.backButton.transform =  CGAffineTransform(rotationAngle: 0)
        }
        UIView.animate(withDuration: 0.1, animations: {
            let color = UIColor(red: 0, green: 0, blue: 0, alpha: percentShift/2)
            self.suggestionController.view.backgroundColor = color
        })
    }
}

// MARK: - SuggestionCallBacks
extension CameraController : SuggestionCallBacks {
    func getTableHeaderView() -> UIView? {
        let paddingView = UIView(frame: .zero)
        paddingView.frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.height/2 - 60)
        paddingView.backgroundColor = .clear
        return paddingView
    }
    
    func shouldShowHeader(forPage page: Int) -> Bool {
        return page == 0 ? false : true
    }
    
    func shouldSelect(suggestion: Suggestion, indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableViewScrolled(scrollView: UIScrollView) {
        changeUI(withCurrentScrollPosition: scrollView.contentOffset.y)
        
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CameraController : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
