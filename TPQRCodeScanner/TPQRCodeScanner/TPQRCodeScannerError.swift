//
//  TPQRCodeScannerError.swift
//  QRCodeScanner
//
//  Created by TuanPham on 11/10/2023.
//

import Foundation
import AVFoundation

public enum TPQRCodeScannerError: Error {
    case unauthorized(AVAuthorizationStatus)
    case deviceFailure(DeviceError)
    case readFailure
    case unknown

    public enum DeviceError {
        case videoUnavailable
        case inputInvalid
        case metadataOutputFailure
        case videoDataOutputFailure
    }
}
