//
//  ViewController.swift
//  MotionRecorder
//
//  Created by Lan, Rick on 2018/06/26.
//  Copyright © 2018 Lan, Rick. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import simd

struct SensorData {
    var roll: [Double] = []
    var pitch: [Double] = []
    var yaw: [Double] = []
    var rotationRateX: [Double] = []
    var rotationRateY: [Double] = []
    var rotationRateZ: [Double] = []
    var userAccelerationX: [Double] = []
    var userAccelerationY: [Double] = []
    var userAccelerationZ: [Double] = []
    var heading: [Double] = []
}

class ViewController: UIViewController {

    @IBOutlet weak var status: UITextField!
    var count: Int!
    var fileURL: URL!
    var data: SensorData! = SensorData()
    var motionManager: CMMotionManager? = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        status.text = "Status Bar"
        count = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetSensorData() {
        count = 0
        data.roll.removeAll()
        data.pitch.removeAll()
        data.yaw.removeAll()
        data.rotationRateX.removeAll()
        data.rotationRateY.removeAll()
        data.rotationRateZ.removeAll()
        data.userAccelerationX.removeAll()
        data.userAccelerationY.removeAll()
        data.userAccelerationZ.removeAll()
        data.heading.removeAll()
    }
    
    func writeSensorData() {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddHHmmss"
        let dateString = dateFormatter.string(from: Date())
        print("dateString: " + dateString)
        //let file = "data" + dateString + ".txt" // Keep extension as .txt. If .csv, sharing doesn't work
        let file_name = "data" + dateString + ".txt" // File name with numbers -> Can not create FileHandle
        print("file_name: " + file_name)
        let file = "data.txt"
        //let file = file_name
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = dir.appendingPathComponent(file)
            print(fileURL.path)
            do {
                let file: FileHandle? = try FileHandle(forWritingTo: fileURL)
                print("Count: " + String(format:"%i", count))
                let header = "roll, pitch, yaw, rotation rate X, rotation rate Y, rotation rate Z, user acceleration X, user acceleration Y, user acceleration Z, heading\n"
                file!.write(header.data(using: .utf8, allowLossyConversion: false)!)
                for i in 0 ..< count {
                    let msg1 = String(format:"%.20g,%.20g,%.20g",
                                      data.roll[i],
                                      data.pitch[i],
                                      data.yaw[i])
                    let msg2 = String(format:"%.20g,%.20g,%.20g",
                                      data.rotationRateX[i],
                                      data.rotationRateY[i],
                                      data.rotationRateZ[i])
                    let msg3 = String(format:"%.20g,%.20g,%.20g",
                                      data.userAccelerationX[i],
                                      data.userAccelerationY[i],
                                      data.userAccelerationZ[i])
                    let msg4 = String(format:"%.20g", data.heading[i])
                    let line = msg1 + "," + msg2 + "," + msg3 + "," + msg4 + "\n"
                    file!.write(line.data(using: .utf8, allowLossyConversion: false)!)
                }
                file!.closeFile()
            } catch {
                print("Error when creating FileHandle")
            }
            
        }
    }
    
    func startQueuedUpdates() {
        guard let motion = motionManager, motion.isDeviceMotionAvailable else {
            // Device motion NOT available
            status.text = "Device motion NOT available"
            return
        }
        
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.showsDeviceMovementDisplay = true
        motion.startDeviceMotionUpdates(
            using: .xMagneticNorthZVertical, // Get the attitude relative to the magnetic north reference frame.
            to: .main, withHandler: { (data, error) in // TODO: main queue not recommended, self.queue
                // Make sure the data is valid before accessing it.
                if let validData = data {
                    self.data.roll.append(validData.attitude.roll)
                    self.data.pitch.append(validData.attitude.pitch)
                    self.data.yaw.append(validData.attitude.yaw)
                    
                    self.data.rotationRateX.append(validData.rotationRate.x)
                    self.data.rotationRateY.append(validData.rotationRate.y)
                    self.data.rotationRateZ.append(validData.rotationRate.z)
                    
                    self.data.userAccelerationX.append(validData.userAcceleration.x)
                    self.data.userAccelerationY.append(validData.userAcceleration.y)
                    self.data.userAccelerationZ.append(validData.userAcceleration.z)
                    
                    self.data.heading.append(validData.heading)

                    self.count = self.count + 1
                }
        })

    }
    
    func stopQueueUpdates() {
        guard let motion = motionManager, motion.isDeviceMotionAvailable else { return }
        motion.stopDeviceMotionUpdates()
    }

    @IBAction func start(_ sender: UIButton) {
        status.text = "Running..."
        resetSensorData()
        startQueuedUpdates()
    }
    @IBAction func stop(_ sender: UIButton) {
        stopQueueUpdates()
        let msg = String(format: "Stopped. count: %i", self.count)
        status.text = msg
    }
    @IBAction func send(_ sender: UIButton) {
        status.text = "Sharing..."
        
        writeSensorData()
        print("after writeSenorData()")
        
        //print(fileURL.path)
        let documentToShare = NSData(contentsOfFile: fileURL.path)
        //let documentToShare = NSData(contentsOfFile: fileURL) // expects a string
        //let documentToShare = fileURL // Box app failed
        //let documentToShare = NSURL.fileURL(withPath: fileURL.path)
        let activityViewController = UIActivityViewController(activityItems: [documentToShare!], applicationActivities: nil)
        // Completion handler for SWIFT 3 AND 4, iOS 10 AND 11 :
        activityViewController.completionWithItemsHandler = {(activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                // User canceled
                self.status.text = "Sharing cancelled"
                return
            }
            // User completed activity
            self.status.text = "Sharing completed"
        }
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // exclude some activity types from the list (optional)
        //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        //status.text = "Sent"
    }
}


