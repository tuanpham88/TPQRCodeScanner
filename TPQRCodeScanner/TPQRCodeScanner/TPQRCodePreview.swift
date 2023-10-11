//
//  TPQrCodePreview.swift
//  QRCodeScanner
//
//  Created by TuanPham on 11/10/2023.
//

import UIKit
import AVFoundation

public class TPQRCodePreview: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("""
                       Expected `AVCaptureVideoPreviewLayer` type for layer.
                       Check PreviewView.layerClass implementation.
                       """)
        }

        return layer
    }

    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

    // MARK: UIView

    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
}
