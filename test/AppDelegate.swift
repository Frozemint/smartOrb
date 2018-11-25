//
//  AppDelegate.swift
//  test
//
//  Created by Nami on 2018-11-24.
//  Copyright © 2018 Nami. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    
    
    @IBOutlet var appStatusMenu: NSMenu!
    @IBOutlet weak var brightnessSliderMenuItem: NSMenuItem!
    
    @IBAction func statusBarLightOn(_ sender: Any){
        switchLightOn(nil)
    }
    
    @IBAction func statusBarLightOff(_ sender: Any){
        switchLightOff(nil)
    }
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    struct Custom: Codable{
        let power: String?
        let brightness: Float?
        let duration: Float?
        let color: String?
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        systemWakeSleepNotification() //register for system power state change notification
        
        statusItem.button?.title = "💡"
        statusItem.menu = appStatusMenu
        
        let brightnessSlider = NSSlider()
        brightnessSliderMenuItem.view = brightnessSlider
        brightnessSlider.setFrameSize(NSSize(width: 160, height: 20))

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("App quitting, switching light off")
        switchLightOff(nil) //turn off lights
        NSWorkspace.shared.notificationCenter.removeObserver(self) //remove all observers
    }
    
    func systemWakeSleepNotification(){
        //This function makes it so that when the macbook go to sleep or wakes from sleep
        //(closing or opening lid) gives us a notification
        //which in turns calls
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(switchLightOff),
                                                          name: NSWorkspace.willSleepNotification,
                                                          object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(switchLightOn),
                                                          name: NSWorkspace.didWakeNotification,
                                                          object: nil)
    }
    
    @objc func switchLightOff(_ notification: Notification?){
        if notification != nil{
            print("System sleeping, turning light off")
        } else {
            print("Turning light off by user action")
        }
        toggleOnOffOfLight(power: "off")
    }
    @objc func switchLightOn(_ notification: Notification?){
        if notification != nil{
            print("System waking, turning light on")
        } else {
            print("Turning light on by user action")
        }
        toggleOnOffOfLight(power: "on")
    }

    func toggleOnOffOfLight(power: String){
        let endpoint = URL(string: "https://api.lifx.com/v1/lights/all/state")
        var urlRequest = URLRequest(url: endpoint!)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        let parameters = Custom(power: power, brightness: nil, duration: nil, color: nil)
        guard let payload = try? JSONEncoder().encode(parameters) else {
            print("Error")
            return
        }
        let task = URLSession.shared.uploadTask(with: urlRequest, from: payload) { data, response, error in
            if error != nil {
                print ("error: \(error!)")
                return
            }
            let response = response as! HTTPURLResponse
            if !(200...299).contains(response.statusCode) {
                print("Server error: server code \(response.statusCode)")
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("Got Data from server: \(dataString)")
            }
        }
        task.resume() //perform the upload task
    }

}

