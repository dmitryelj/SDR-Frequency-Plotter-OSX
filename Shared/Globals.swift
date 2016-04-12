//
//  Globals.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

import Cocoa

enum RecieverType:String {
  case Unknown = "Unknown"
  case HackRF  = "HackRF"
  case SDRPlay = "SDRplay"
  case RTLSDR  = "RTL-SDR"
  case Demo    = "Demo"
}

enum RecieverStatus:Int {
  case NotFound = 0
  case Disconnected = 1
  case Connected = 2
}

class Helpers {

  static func delay(delay:Double, closure:()->()) {
    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
    dispatch_async(backgroundQueue, {
      
      NSThread.sleepForTimeInterval(delay)
      dispatch_async(dispatch_get_main_queue(), closure)
    })
  }
}

extension Int {
  var M: CGFloat { return CGFloat(self) * CGFloat(1000000) }
  var K: CGFloat { return CGFloat(self) * CGFloat(1000) }
}

extension String {
  var length: Int { return self.characters.count }
  
  func contains(s:String) -> Bool {
    return (self as NSString).containsString(s)
  }
  
  func charAt(index:Int) -> String {
    let c = (self as NSString).characterAtIndex(index)
    let s = NSString(format:"%c",c)
    return s as String
  }
  
  func trim() -> String {
    return (self as String).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
  }
  
  var localized: String {
    return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
  }
}
