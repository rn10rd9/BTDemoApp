//
//  BTServiceDemoApp.swift
//  BTDEMOAPP
//
//  Created by Christian Chabikuli on 2016-12-21.
//  Copyright © 2016 Christian Chabikuli. All rights reserved.
//

import Foundation

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let BLEModuleServiceUUID = CBUUID(string: "0000dfb0-0000-1000-8000-00805f9b34fb")
let kBlunoDataCharacteristic  = CBUUID(string: "0000dfb1-0000-1000-8000-00805f9b34fb")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTModuleService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([BLEModuleServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForBTService: [CBUUID] = [kBlunoDataCharacteristic ]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.uuid == BLEModuleServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, for: service)
                NSLog("Discovered service: %@",service);
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == kBlunoDataCharacteristic {
                    // self.positionCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                    NSLog("Discovered characteristic: %@", characteristic)
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        var size:UInt8 = 0;
        //var data: String
        
        if characteristic.uuid == kBlunoDataCharacteristic {
            characteristic.value!.copyBytes(to: &size, count: MemoryLayout<UInt32>.size)
               // NSLog(NSString(format: "%", size) as String)
            var value = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            print("Value \(value)")
        
        }
        
    }

    

    // Mark: - Private
    
    func readData(_ characteristic: CBCharacteristic, error: Error?)
    {
        
        /******** (1) CODE TO BE ADDED *******
        let data = characteristic.value!;
        // Display the heart rate value to the UI if no error occurred
        if((characteristic.value != nil) || !(error != nil) ) {   // 4

            NSLog("VALUE RECEIVED IS %@", data)
        }
        */
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
    }
    
}

