//
//  ConnectionViewController.swift
//  BTDEMOAPP
//
//  Created by Christian Chabikuli on 2017-01-27.
//  Copyright © 2017 Christian Chabikuli. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func scanBTN(_ sender: Any) {
        btDiscoverySharedInstance
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //We set the cell title according to the peripheral's name
       // let peripheral: CBPeripheral = self.peripheral!
        cell.textLabel?.text = "Hello"
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Hello World"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       // let peripheral: CBPeripheral = self.peripheral!
       // centralManager?.connect(peripheral, options: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func hello()
    {
        print("HELLO")
    }
    

}
