//
//  BTModuleViewController.swift
//  BTDEMOAPP
//
//  Created by Christian Chabikuli on 2017-01-24.
//  Copyright © 2017 Christian Chabikuli. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class BTModuleViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    //Variable intializations
    
    //@IBOutlet weak var output: UILabel!
    @IBOutlet weak var outputLabel: UILabel!
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var isBluetoothEnabled = false
    fileprivate var isConnected = false
    fileprivate var peripheralBLE: CBPeripheral?
    fileprivate var scanTimer: Timer?
    fileprivate var connectionAttemptTimer: Timer?
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var peripheral: CBPeripheral?
    
    // UUID and characteristics
    let BLEModuleServiceUUID = CBUUID(string: "0000dfb0-0000-1000-8000-00805f9b34fb")
    let kBlunoDataCharacteristic  = CBUUID(string: "0000dfb1-0000-1000-8000-00805f9b34fb")
    
   /* required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        self.peripheralBLE?.delegate = self
    
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    */
 
    override func viewDidLoad() {
        super.viewDidLoad()

            // Do any additional setup after loading the view, typically from a nib.
            //init CBCentralManager and its delegate
            outputLabel.text = "Waiting for device..."
            centralManager = CBCentralManager(delegate: self, queue: nil)
            //peripherals = NSMutableArray()
            let scanButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.startScanning))
            self.navigationItem.rightBarButtonItem = scanButton
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    
    private func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //We set the cell title according to the peripheral's name
        let peripheral: CBPeripheral = self.peripheral!
        cell.textLabel?.text = peripheral.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral: CBPeripheral = self.peripheral!
        centralManager?.connect(peripheral, options: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //We set the cell title according to the peripheral's name
        //var peripheral: CBPeripheral? = peripheralBLE[indexPath.row]
        cell?.textLabel?.text = peripheral?.name
        return cell!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func timeoutPeripheralConnectionAttempt()
    {
        outputLabel.text = "Connection attempt timed out..."
        if let connectedPeripheral = connectedPeripheral
        {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectionAttemptTimer?.invalidate()
        outputLabel.text = "Make sure the device is ON"
    }
    
    
    func startScanning()
    {
        
        if let central = centralManager
        {
            if isConnected
            {
                
                //isConnected = true
                outputLabel.text = "Device is already connected"
            }
            else{
                central.scanForPeripherals(withServices: [BLEModuleServiceUUID], options: nil)
                outputLabel.text = "Scanning..."
                scanTimer = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(BTDiscoveryViewController.timeoutPeripheralConnectionAttempt), userInfo: nil, repeats: false)
                //output.text = "Device is already connected"
            }
            
        }
    }
    
    func stopScanning()
    {
        print("Stopped scanning.")
        //print("Found \(visiblePeripherals.count) peripherals.")
        centralManager?.stopScan()
        //refreshControl?.endRefreshing()
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
            
            /*if !peripherals.contains(peripheral) {
                peripherals.append(peripheral)
            }
            self.tableView.reloadData()*/
            
            // Connect to peripheral
            central.connect(peripheral, options: nil)
            outputLabel.text = "Bluno Board is now connected"
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            peripheral.delegate = self
            peripheral.discoverServices(nil)

        }
        
        central.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was our peripheral that disconnected
        //if (peripheral == self.peripheralBLE) {
            //self.bleService = nil;
            peripheral.delegate = nil
            print("Bluno Board is disconnected")
            outputLabel.text = "Bluno Board is disconnected"
        //}
        
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

    
    // MARK: CBPeripheral Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForBTService: [CBUUID] = [kBlunoDataCharacteristic ]
        
       /* if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }*/
        
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
       /* if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }*/
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == kBlunoDataCharacteristic {
                    // self.positionCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    //self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                    NSLog("Discovered characteristic: %@", characteristic)
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        //var data: String
        
        if characteristic.uuid == kBlunoDataCharacteristic {
            let value = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            print("Value \(value)")
            
        }
        
    }
    
}