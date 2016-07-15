//
//  ViewController.swift
//  CoreImageExample
//
//  Created by Yuta Akizuki on 2016/07/15.
//  Copyright © 2016年 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var session: AVCaptureSession!
    var device: AVCaptureDevice!
    var output: AVCaptureVideoDataOutput!
    
    let detector = CIDetector(ofType: CIDetectorTypeFace,
                              context: nil,
                              options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if initialize() {
            
            session.startRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() -> Bool {
        
        session = AVCaptureSession()
        
        session.sessionPreset = AVCaptureSessionPreset1280x720
        
        let devices = AVCaptureDevice.devices()
        
        for device in devices {
            
            if device.position == AVCaptureDevicePosition.Back,
                let device = device as? AVCaptureDevice {
                
                self.device = device
            }
        }
        
        if device == nil { return false }
        
        do {
            
            let myInput = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(myInput) {
                
                session.addInput(myInput)
                
            } else {
                
                return false
            }
            
            output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
            
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            device.unlockForConfiguration()
            
        } catch {
            
            return false
        }
        
        let queue = dispatch_queue_create("myqueue",  nil)
        output.setSampleBufferDelegate(self, queue: queue)
        
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            
            session.addOutput(output)
            
        } else {
            
            return false
        }
        
        for connection in output.connections {
            
            if let conn = connection as? AVCaptureConnection {
                
                if conn.supportsVideoOrientation {
                    
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        
        return true
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_sync(dispatch_get_main_queue(), {
            
            if let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                
                self.draw(CIImage(CVPixelBuffer: buffer))
            }
            
        })
    }
    
    func draw(ciImage: CIImage) {
        
        let size     = ciImage.extent.size
        
        let features = self.detector.featuresInImage(ciImage)
        
        var faceRect = CGRectZero
        
        for feature in features {
            
            if let feature = feature as? CIFaceFeature {
                
                faceRect = feature.bounds
                faceRect.origin.y = size.height - faceRect.origin.y - faceRect.size.height
            }
        }
        
        let image = UIImage(CIImage: ciImage)
        
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        let drawCtxt = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(drawCtxt, UIColor.redColor().CGColor)
        CGContextStrokeRect(drawCtxt,faceRect)
        
        let drawedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView.image = drawedImage
    }
}
