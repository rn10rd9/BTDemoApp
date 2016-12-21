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

let btDiscoverySharedInstance = BTDiscoveryViewController()

class BTDiscoveryViewController: UIViewController, CBCentralManagerDelegate  {
    
    @IBOutlet weak var Output: UIScrollView!
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var peripheralBLE: CBPeripheral?
    fileprivate var scanTimer: Timer?
    fileprivate var connectionAttemptTimer: Timer?
    fileprivate var connectedPeripheral: CBPeripheral?

    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

        // Do any additional setup after loading the view.
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timeoutPeripheralConnectionAttempt()
    {
        print("Peripheral connection attempt timed out. Make sure the Bluno board is powered ON")
        if let connectedPeripheral = connectedPeripheral
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
            NSLog("Scanning...")
            scanTimer = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(BTDiscoveryViewController.timeoutPeripheralConnectionAttempt), userInfo: nil, repeats: false)
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
            NSLog("Device [%@] is connected...",BLEModuleServiceUUID )
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            self.bleService = BTModuleService(initWithPeripheral: peripheral)
        }
        
         central.stopScan()

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was our peripheral that disconnected
        if (peripheral == self.peripheralBLE) {
            self.bleService = nil;
            self.peripheralBLE = nil;
        }
        
        // Start scanning for new devices
        self.startScanning()
    }
    
    // MARK: - Private
    
    func clearDevices() {
        self.bleService = nil
        self.peripheralBLE = nil
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            NSLog("BLE PoweredOff")
            self.clearDevices()
            
        case .unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            NSLog("BLE Unauthorized")
            break
            
        case .unknown:
            // Wait for another event
            break
            
        case .poweredOn:
            NSLog("BLE poweredOn")
            self.startScanning()
            
        case .resetting:
            self.clearDevices()
            
        case .unsupported:
            break
            
        }
    }
    
    
}


    


