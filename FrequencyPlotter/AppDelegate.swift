//
//  AppDelegate.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com
//  Install:
//  otool -L /Users/dmitriieliuseev/Documents/Temp/FrequencyPlotter
//  install_name_tool -change libSoapySDR.0.5-1.dylib /usr/local/lib/libSoapySDR.0.5-1.dylib FrequencyPlotter

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
    // Close app by pressing the Close button
    return true
  }
  
  func appVersion() -> String {
    return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
  }
  
  func appBuild() -> String {
    return NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
  }
  
  func versionBuild() -> String {
    let version = appVersion(), build = appBuild()
    
    return version == build ? "v\(version)" : "v\(version)(\(build))"
  }

}
