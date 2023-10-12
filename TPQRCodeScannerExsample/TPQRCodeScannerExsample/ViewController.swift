//
//  ViewController.swift
//  TPQRCodeScannerExsample
//
//  Created by TuanPham on 12/10/2023.
//

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
