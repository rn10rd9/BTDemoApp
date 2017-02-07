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
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var outputLabel: UILabel!
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var isBluetoothEnabled = false
    fileprivate var isConnected = false
    fileprivate var scanTimer: Timer?
    fileprivate var connectionAttemptTimer: Timer?
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var peripheral: CBPeripheral?
    fileprivate var peripherals: [CBPeripheral?] = []
    var strArr = [String]()
    
    // UUID and characteristics
    let BLEModuleServiceUUID = CBUUID(string: "0000dfb0-0000-1000-8000-00805f9b34fb")
    let kBlunoDataCharacteristic  = CBUUID(string: "0000dfb1-0000-1000-8000-00805f9b34fb")
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self

        //init CBCentralManager and its delegate
        
        outputLabel.text = "Waiting for device..."
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //We set the cell title according to the peripheral's name
        let peripheral: CBPeripheral = self.peripherals[indexPath.row]!
        cell.textLabel?.text = peripheral.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let peripheral: CBPeripheral = self.peripherals[indexPath.row]!
        centralManager?.connect(peripheral, options: nil)
        // Connect to peripheral
        outputLabel.text = "Bluno Board is now connected"
    }
    
    
    func timeout()
    {
        //outputLabel.text = "Connection attempt timed out..."
        if let connectedPeripheral = connectedPeripheral
        {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectionAttemptTimer?.invalidate()
        scanTimer?.invalidate()
        outputLabel.text = "Make sure the device is ON"
    }
    
    
    func startScanning()
    {
        outputLabel.text = "Scanning..."
        if let central = centralManager
        {
            central.scanForPeripherals(withServices: [BLEModuleServiceUUID], options: nil)
            
            scanTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(BTModuleViewController.timeout), userInfo: nil, repeats: false)
        }
        //output.text = "Device is already connected"
        
    }
    
    func stopScanning()
    {
        print("Stopped scanning.")
        //print("Found \(visiblePeripherals.count) peripherals.")
        centralManager?.stopScan()
        //refreshControl?.endRefreshing()
        scanTimer?.invalidate()
       // outputLabel.text = "Make sure the device is ON"
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.peripheral == nil) || (self.peripheral?.state == CBPeripheralState.disconnected))
        {
            // Retain the peripheral before trying to connect
            self.peripheral = peripheral
            
            // Reset service
           // self.bleService = nil
            

            //central.connect(peripheral, options: nil)
            outputLabel.text = "Found " + peripheral.name! + " device"
            
            peripherals.append(peripheral)
            self.tableView.reloadData()
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheral) {
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            //print("Connected")
            isConnected = true
            
        }
        
        central.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was our peripheral that disconnected
        //if (peripheral == self.peripheralBLE) {
        //self.bleService = nil;
        peripheral.delegate = nil
        isConnected = false
        print("Bluno Board is disconnected")
        //outputLabel.text = "Bluno Board is disconnected"
        //}
        self.peripherals = []
        // Start scanning for new devices
        self.startScanning()
    }
    
    // MARK: - Private
    
    func clearDevices() {
        //self.bleService = nil
        self.peripheral = nil
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

            
        case .resetting:
            self.clearDevices()
            
        case .unsupported:
            break
            
        }
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
                //NSLog("Discovered service: %@",service);
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
                    //self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                    //NSLog("Discovered characteristic: %@", characteristic)
                    //print("HERE")
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        //var data: String
       // var result: Float = 0.0
        
        if characteristic.uuid == kBlunoDataCharacteristic {
            let value = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            print("Value \(value)")
            for index in 0...4{
                strArr.append(value!)
                
                //print("string array")
                //index += 1
                
            }
            
            
        
            
            
            var index = 0
            for val in strArr{
               print(strArr[index])
                index+=1
        
            }
            //let num = NumberFormatter().number(from: value!)?.floatValue
           //result = (num as? Float)!
           //print("Value \(num)")
            
        }
        
    }
    
    
    
    // Mark: - Private
    
    func storeStringData(_ data: String) ->[String]{
        var strArr = [String]()
        
        if (data != "\r\n"){
            strArr.append(data)
            
            //print("string array is  \(strArr[index])")
            //index += 1
            
        }
        
        return strArr
    }
    
    func convertToFloat(){
        
    }
  
    func isNumeric(a: String) -> Bool {
        return Float(a) != nil
    }
    
    @IBAction func ScanButton(_ sender: UIButton) {
        let central = centralManager
        if (central?.state == .poweredOn && !isConnected)
        {
            self.startScanning()
        }
        
        else{
            outputLabel.text = "Device is already connected"
        }
    }
    

}
