//
//  TPQrCodeScannerView.swift
//  QRCodeScanner
//
//  Created by TuanPham on 11/10/2023.
//

import UIKit
import AVFoundation


// MARK: - TPQRCodeScannerViewDelegate
public protocol TPQRCodeScannerViewDelegate: AnyObject {
    // Required
    func qrCodeScanner(_ view: TPQRCodeScannerView, didFailure error: TPQRCodeScannerError)
    func qrCodeScanner(_ view: TPQRCodeScannerView, didSuccess code: String)
}

@IBDesignable
public class TPQRCodeScannerView: UIView {

    // MARK: - Public Properties
    @IBInspectable
    public var focusColor: UIColor?
    
    public func configure(focusColor: UIColor? = nil, delegate: TPQRCodeScannerViewDelegate) {
        self.focusColor = focusColor ?? UIColor.green
        self.delegate = delegate
        self.addSubview(qrCodeFrameView)
        self.bringSubviewToFront(qrCodeFrameView)
        checkCameraPermission()
    }
    
    private weak var delegate: TPQRCodeScannerViewDelegate?
    
    private let previewView = TPQRCodePreview()
    
    // MARK: Capture related objects
    private let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "com.tp.qrcodescanner.captureSessionQueue")

    private let metaDataOutput = AVCaptureMetadataOutput()
    private let metadataQueue = DispatchQueue(label: "com.tp.qrcodescanner.metadataQueue")
    
    private var captureDevice: AVCaptureDevice?
    
    private var currentOrientation = UIDeviceOrientation.portrait
    private var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    
    // MARK: Coordinate transforms
    private var bufferAspectRatio: Double!
    private var uiRotationTransform = CGAffineTransform.identity
    private var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    private var roiToGlobalTransform = CGAffineTransform.identity
    private var visionToAVFTransform = CGAffineTransform.identity
    
    private var metadataOutputEnable = false
    
    private lazy var qrCodeFrameView: UIView = {
        let qrView = UIView()
        qrView.layer.borderColor = self.focusColor!.cgColor
        qrView.layer.borderWidth = 4
        return qrView
    }()
    
    public func startRunning() {
        guard isAuthorized() else { return }
        guard !captureSession.isRunning else { return }
        metadataOutputEnable = true
        metadataQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    public func stopRunning() {
        guard captureSession.isRunning else { return }
        metadataQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        metadataOutputEnable = false
    }
    
    public func setTorchActive(isOn: Bool) {
        assert(Thread.isMainThread)
        
        guard let videoDevice = AVCaptureDevice.default(for: .video),
            videoDevice.hasTorch, videoDevice.isTorchAvailable,
            (metadataOutputEnable) else {
                return
        }
        try? videoDevice.lockForConfiguration()
        videoDevice.torchMode = isOn ? .on : .off
        videoDevice.unlockForConfiguration()
    }
    
    private func checkCameraPermission() {
           switch AVCaptureDevice.authorizationStatus(for: .video) {
           case .authorized:
               DispatchQueue.main.async { [weak self] in
                   self?.setupQrScanner()
               }
           case .notDetermined:
               AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                   if granted {
                       DispatchQueue.main.async { [weak self] in
                           self?.setupQrScanner()
                       }
                   }
                   else {
                       self?.failure(TPQRCodeScannerError.unauthorized(.denied))
                   }
               }
           default:
               DispatchQueue.main.async { [weak self] in
                   self?.failure(TPQRCodeScannerError.unknown)
               }
           }
       }
    
    private enum AuthorizationStatus {
        case authorized, notDetermined, restrictedOrDenied
    }

    private func isAuthorized() -> Bool {
        return authorizationStatus() == .authorized
    }

    private func authorizationStatus() -> AuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            failure(.unauthorized(.notDetermined))
            return .notDetermined
        case .denied:
            failure(.unauthorized(.denied))
            return .restrictedOrDenied
        case .restricted:
            failure(.unauthorized(.restricted))
            return .restrictedOrDenied
        @unknown default:
            return .restrictedOrDenied
        }
    }
    
    private func setupQrScanner(){
        self.insetsLayoutMarginsFromSafeArea = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(previewView, belowSubview: qrCodeFrameView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: self.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        previewView.session = captureSession
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        captureSessionQueue.async {
            self.setupCamera()
            DispatchQueue.main.async {
                self.calculateRegionOfInterest()
            }
        }
    }
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: AVMediaType.video,
                                                          position: .back) else {
            failure(.deviceFailure(.videoUnavailable))
            return
        }
        self.captureDevice = captureDevice
        
        if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
        }

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            failure(.deviceFailure(.inputInvalid))
            return
        }

        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }

        guard captureSession.canAddOutput(metaDataOutput) else {
            failure(.deviceFailure(.metadataOutputFailure))
            return
        }
        
        captureSession.addOutput(metaDataOutput)
        metaDataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        metaDataOutput.metadataObjectTypes = [.qr]

        // Set zoom and autofocus to help focus on very small text.
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = 1.5
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            return
        }

    }
    
    private func calculateRegionOfInterest() {
        let desiredHeightRatio = 0.10
        // Figure out size of ROI.
        var size: CGSize
        if (currentOrientation.isPortrait || currentOrientation == .unknown) &&  (bufferAspectRatio != nil) {
            size = CGSize(width: (desiredHeightRatio / bufferAspectRatio) * 2,
                          height: (desiredHeightRatio / bufferAspectRatio))
        } else {
            size = CGSize(width: desiredHeightRatio, height: desiredHeightRatio)
        }
        // Make it centered.
        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        regionOfInterest.size = size

        setupOrientationAndTransform()
        DispatchQueue.main.async {
            self.updateCutout()
        }
    }

    private func updateCutout() {
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = previewView.videoPreviewLayer.layerRectConverted(
            fromMetadataOutputRect: regionOfInterest
                .applying(roiRectTransform)
        )
        qrCodeFrameView.frame = cutout
        
    }
    
    private func setupOrientationAndTransform() {
        // Compensate for region of interest.
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x,
                                                 y: roi.origin.y)
            .scaledBy(x: roi.width, y: roi.height)

        // Compensate for orientation (buffers always come in the same orientation).
        switch currentOrientation {
        case .landscapeLeft:
            uiRotationTransform = CGAffineTransform.identity
        case .landscapeRight:
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)
        case .portraitUpsideDown:
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)
        default: // We default everything else to .portraitUp
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
        }

        // Full Vision ROI to AVF transform.
        visionToAVFTransform = roiToGlobalTransform
            .concatenating(bottomToTopTransform)
            .concatenating(uiRotationTransform)
    }
    
    private func failure(_ error: TPQRCodeScannerError) {
        delegate?.qrCodeScanner(self, didFailure: error)
    }

    private func success(_ code: String) {
        delegate?.qrCodeScanner(self, didSuccess: code)
    }

}

extension TPQRCodeScannerView: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataOutputEnable else { return }
        if let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            if metadataObj.type == AVMetadataObject.ObjectType.qr && metadataObj.stringValue != nil  {
                metadataOutputEnable = false
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    //onFlashCamera(isOn: false)
                    //captureSession.stopRunning()
                    strongSelf.stopRunning()
                    strongSelf.moveImageViews(meta: metadataObj)
                }
            }
        }
        
    }
    
    private func moveImageViews(meta: AVMetadataMachineReadableCodeObject) {
        let corners = meta.corners
        let qrCode = meta.stringValue ?? ""
        let aSide: CGFloat
        let bSide: CGFloat
        if corners[0].x < corners[1].x {
            aSide = corners[0].x - corners[1].x
            bSide = corners[1].y - corners[0].y
        } else {
            aSide = corners[2].y - corners[1].y
            bSide = corners[2].x - corners[1].x
        }
        let degrees = atan(aSide / bSide)
        UIView.animate(
            withDuration: 0.5,
            animations: { [weak self] in
                guard let self = self else { return }
                let barCodeObject = self.previewView.videoPreviewLayer.transformedMetadataObject(for: meta)
                self.qrCodeFrameView.frame = barCodeObject!.bounds
                self.qrCodeFrameView.transform = CGAffineTransform.identity.rotated(by: degrees)
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.success(qrCode)
            }
        )
    }
    
    
}
