//
//  AppDelegate.swift
//  test
//
//  Created by Nami on 2018-11-24.
//  Copyright © 2018 Nami. All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var lightStatus: Bool?
    
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
        let brightness: Double?
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
        brightnessSlider.target = self
        brightnessSlider.isContinuous = false
        brightnessSlider.action = #selector(onBrightnessSliderChange)
    }
    
    @objc func onBrightnessSliderChange(sender: NSSlider){
        print(sender.floatValue)
        changeLightState(power: "on", brightness: sender.doubleValue, duration: nil, color: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("App quitting, switching light off")
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
        changeLightState(power: "off", brightness: nil, duration: 0.5, color: nil)
    }
    @objc func switchLightOn(_ notification: Notification?){
        if notification != nil{
            print("System waking, turning light on")
        } else {
            print("Turning light on by user action")
        }
        changeLightState(power: "on", brightness: nil, duration: 0.9, color: nil)
    }

    func changeLightState(power: String?, brightness: Double?, duration: Float?, color: String?){
        let endpoint = URL(string: "https://api.lifx.com/v1/lights/all/state")
        var urlRequest = URLRequest(url: endpoint!)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        let parameters = Custom(power: power, brightness: brightness, duration: duration, color: color)
        guard let payload = try? JSONEncoder().encode(parameters) else {
            print("Error encoding JSON")
            return
        }
        print(String(data: payload, encoding: .utf8)!)
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

    
//    func getLightStatus(){
//        let endpoint = URL(string: "https://api.lifx.com/v1/lights/all")
//        var urlRequest = URLRequest(url: endpoint!)
//        urlRequest.httpMethod = "GET"
////        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
//        let task = URLSession.shared.dataTask(with: urlRequest as URLRequest, completionHandler: { data, response, error in
//            guard error == nil else {
//                return
//            }
//            guard let data = data else {
//                return
//            }
//            let first = data.first
//            let dataString = String(data: first, encoding: .utf8)
//            print(dataString!)
////            print(dataString!)
////            let decoder = JSONDecoder()
////            let user = try! decoder.decode(Custom.self, from: data)
////            print(user.power!)
//        })
//
//        task.resume()
//    }

//}
}

