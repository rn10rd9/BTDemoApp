//
//  BTDiscoveryViewController.swift
//  BTDEMOAPP
//
//  Created by Christian Chabikuli on 2016-12-21.
//  Copyright © 2016 Christian Chabikuli. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth


let btDiscoverySharedInstance = BTDiscovery()
class BTDiscovery:  NSObject,  CBCentralManagerDelegate  {
    
    
    
    @IBOutlet weak var output: UILabel!
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var isBluetoothEnabled = false
    fileprivate var isConnected = false
    fileprivate var peripheralBLE: CBPeripheral?
    fileprivate var scanTimer: Timer?
    fileprivate var connectionAttemptTimer: Timer?
    fileprivate var connectedPeripheral: CBPeripheral?
    
    var peripherals: NSMutableArray?
    
    
    override init() {
        super.init()
        
       // let centralQueue = DispatchQueue(label: "com.raywenderlich", attributes: [])
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    
    func timeoutPeripheralConnectionAttempt()
    {
        print("Make sure the Bluno board is powered ON")
        if let connectedPeripheral = self.connectedPeripheral
        {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectionAttemptTimer?.invalidate()
    }
    
    func startScanning()
    {
        
        if let central = centralManager
        {

                central.scanForPeripherals(withServices: [BLEModuleServiceUUID], options: nil)
                print("Scanning...")
                scanTimer = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(BTDiscovery.timeoutPeripheralConnectionAttempt), userInfo: nil, repeats: false)

            
        }
    }
    
    func stopScanning()
    {
        print("Stopped scanning.")
        //print("Found \(visiblePeripherals.count) peripherals.")
        centralManager?.stopScan()
        // refreshControl?.endRefreshing()
        scanTimer?.invalidate()
    }
    
    var bleService: BTModuleService?
        {
        didSet
        {
            if let service = self.bleService
            {
                service.startDiscoveringServices()
            }
        }
    }
    
    func getPeripheralName()->CBPeripheral
    {
        let peripheral: CBPeripheral = self.peripheralBLE!
        return peripheral
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.disconnected)) {
            // Retain the peripheral before trying to connect
            self.peripheralBLE = peripheral
            
            // Reset service
            self.bleService = nil
            
            // Connect to peripheral
            central.connect(peripheral, options: nil)
            print("Bluno Board is now connected")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            self.bleService = BTModuleService(initWithPeripheral: peripheral)
            isConnected = true
        }
        
        central.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was our peripheral that disconnected
        if (peripheral == self.peripheralBLE) {
            self.bleService = nil;
            self.peripheralBLE = nil;
            //print("Our device is disconnected")
        }
        
        // Start scanning for new devices
        self.startScanning()
        print("Bluno Board is disconnected")
    }
    
    // MARK: - Private
    
    func clearDevices() {
        self.bleService = nil
        self.peripheralBLE = nil
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            isBluetoothEnabled = false
            NSLog("BLE PoweredOff")
            self.clearDevices()
            
        case .unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            NSLog("BLE Unauthorized")
            isBluetoothEnabled = false
            break
            
        case .unknown:
            // Wait for another event
            isBluetoothEnabled = false
            break
            
        case .poweredOn:
            NSLog("BLE poweredOn")
            self.startScanning()
            isBluetoothEnabled = true
            
        case .resetting:
            isBluetoothEnabled = false
            self.clearDevices()
            
        case .unsupported:
            break
            
        }
    }
}





