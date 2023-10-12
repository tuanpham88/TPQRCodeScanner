# TPQRCodeScanner

A simple QR Code scanner framework for iOS. Provides a similar scan effect to ios13+. Written in Swift.

## Development Requirements
- iOS 12.0+
- Swift: 5.7.1
- Xcode Version: 14.1

### Installation with Swift Package Manager

Once you have your Swift package set up, adding TPQRCodeScanner as a dependency is as easy as adding it to the dependencies value of your <code>Package.swift</code>.
```
dependencies: [
    .package(url: "https://github.com/tuanpham88/TPQRCodeScanner.git", .upToNextMajor(from: "1.0.4"))
]
```

- Write Import statement on your source file
```swift
import TPQRCodeScanner
```
### Add `Privacy - Camera Usage Description` to Info.plist file
```
<key>NSCameraUsageDescription</key>
<string>Camera Usage Description</string>

```

### The Basis Of Usage

```swift
 // Add scan view and start scan
let scannerView = TPQRCodeScannerView(frame: view.bounds)
view.insertSubview(scannerView, belowSubview: btnFlash)
scannerView.configure(focusColor: UIColor.red, delegate: self)
scannerView.startRunning()

// On/Off flash of camera
scannerView.setTorchActive(isOn: On/Off)

// Result of scan 
extension ViewController: TPQRCodeScannerViewDelegate {
    func qrCodeScanner(_ view: TPQRCodeScannerView, didFailure error: TPQRCodeScannerError) {
        print("TPQRCodeScanner: \(error)")
    }
    
    func qrCodeScanner(_ view: TPQRCodeScannerView, didSuccess code: String){
        print("TPQRCodeScanner: \(code)")
    }
}
```

## License

Copyright 2023 TuanPham.

Licensed under the MIT License.
