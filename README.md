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
    .package(url: "https://github.com/tuanpham88/TPQRCodeScanner.git", .upToNextMajor(from: "1.0.2"))
]
```

- Write Import statement on your source file
```swift
import TPQRCodeScanner
```
### Add `Privacy - Camera Usage Description` to Info.plist file

### The Basis Of Usage

```swift
import UIKit
import AVFoundation
import TPQRCodeScanner

class ViewController: UIViewController {

    @IBOutlet weak var btnFlash: UIButton!
    var scannerView: TPQRCodeScannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnFlash.setTitle("On", for: .normal)
        btnFlash.setTitle("Off", for: .selected)
        createQRCodeScanner()
    }

    func createQRCodeScanner(){
        scannerView = TPQRCodeScannerView(frame: view.bounds)
        view.insertSubview(scannerView, belowSubview: btnFlash)
        scannerView.configure(focusColor: UIColor.red, delegate: self)
        self.startQrScan()
    }
    
    private func showErrorAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Error", message: "Camera is required to use in this application", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func showSuccessAlert(code:String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Success", message: code, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: { [weak self] _ in
                self?.startQrScan()
            }))
            self?.present(alert, animated: true)
        }
    }
    
    func startQrScan(){
        self.scannerView.startRunning()
    }
    
    @IBAction func flashSubmit(_ sender: UIButton) {
        btnFlash.isSelected = !btnFlash.isSelected
        scannerView.setTorchActive(isOn: btnFlash.isSelected)
    }
    

}

extension ViewController: TPQRCodeScannerViewDelegate {
    func qrCodeScanner(_ view: TPQRCodeScannerView, didFailure error: TPQRCodeScannerError) {
        print("TPQRCodeScanner: \(error)")
        showErrorAlert()
    }
    
    func qrCodeScanner(_ view: TPQRCodeScannerView, didSuccess code: String){
        print("TPQRCodeScanner: \(code)")
        showSuccessAlert(code: code)
    }
}
```

## License

Copyright 2023 TuanPham.

Licensed under the MIT License.
