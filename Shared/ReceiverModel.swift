//
//  ReceiverModel.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

import Cocoa

public protocol ReceiverModelDelegate {
  func onDataDidReceived(points: UnsafeMutablePointer<Float>, count: Int)
}

class ReceiverModel: NSObject {
  
  var sampleRate = 4000000
  var receiver = RecieverType.Unknown
  var receiverStatus = RecieverStatus.NotFound
  var receiverName = ""
  var maximumFreqShift:CGFloat = 1500000
  var switchTimeInBlocks = 1
  var switchTimeInBlocksFast = 1
  var delegate: ReceiverModelDelegate? = nil

  func connectReceiver() -> Bool { return false }
  func disconnect() { receiverStatus = .Disconnected  }
  func startRX() -> Bool { return true }
  func stopRX() {  }
  func didReceiveData() {  }
  
  func isRX() -> Bool { return false }
  
  func setFrequency(frequency:CGFloat) { }
  func getFrequency() -> CGFloat { return 0 }
  
  func getAmp1Title() -> String { return "" }
  func getAmp1Val() -> Int { return 0 }
  func getAmp1Min() -> Int { return 0 }
  func getAmp1Max() -> Int { return 100 }
  func setAmp1Val(val:Int) {}
  func getAmp2Title() -> String { return "" }
  func getAmp2Val() -> Int { return 0 }
  func getAmp2Min() -> Int { return 0 }
  func getAmp2Max() -> Int { return 100 }
  func setAmp2Val(val:Int) {}
  func loadSettings() {}
}

class DemoReceiverModel: ReceiverModel {
  
  var demoTimer:NSTimer? = nil
  
  override init() {
    super.init()
    sampleRate = 1000000
    maximumFreqShift = 500000
    receiver = RecieverType.Demo
    receiverName = RecieverType.Demo.rawValue
  }
  
  override func connectReceiver() -> Bool {
    receiverStatus = .Connected
    return true
  }
  
  override func disconnect() {
    receiverStatus = .Disconnected
  }
  
  override func startRX() -> Bool {
    if demoTimer == nil {
      demoTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(DemoReceiverModel.demoUpdate(_:)), userInfo: nil, repeats: true)
    }
    return true
  }
  
  override func stopRX() {
    if let t = demoTimer {
      t.invalidate()
    }
    demoTimer = nil
  }
  
  override func isRX() -> Bool {
    return demoTimer != nil
  }
  
  override func getAmp1Title() -> String {
    return "Demo Settings 1"
  }
  
  func demoUpdate(timer: NSTimer!) {
    didReceiveData()
  }
  
  var floats = [Float](count:262987, repeatedValue: 0)
  
  override func didReceiveData() {
    if let delegate = self.delegate {
      // Set random
      for p in 0..<floats.count {
        floats[p] = Float(arc4random_uniform(64))
      }
      delegate.onDataDidReceived(UnsafeMutablePointer(floats), count: floats.count)
    }
  }
}

class SoapyReceiverModel: ReceiverModel, SoapyReceiverImplDelegate {
  
  let soapyReceiver = SoapyReceiverImpl()
  var receiverLibrary = ""
  
  override init() {
    super.init()
    sampleRate = 4000000
    maximumFreqShift = 1000000
    receiver = RecieverType.Unknown
  }
  
  override func connectReceiver() -> Bool {    
    if receiverLibrary.length == 0 {
      receiverStatus = .NotFound
      return false
    }
    
    let res = soapyReceiver.initLib(Int32(sampleRate), library:receiverLibrary)
    if res == EXIT_SUCCESS {
      soapyReceiver.delegate = self
      receiverStatus = .Connected
      return true
    }
    receiverStatus = .NotFound
    return false
  }
  
  override func disconnect() {
    if receiverStatus == .Connected {
      soapyReceiver.closeLib()
      receiverStatus = .Disconnected
    }
  }

  override func startRX() -> Bool {
    if receiverStatus == .Connected {
      return soapyReceiver.startRX() == EXIT_SUCCESS
    }
    return false
  }
  
  override func stopRX() {
    if receiverStatus == .Connected {
      soapyReceiver.stopRX()
    }
  }
  
  override func isRX() -> Bool {
    if receiverStatus == .Connected {
      return soapyReceiver.isModeRX()
    }
    return false
  }
  
  override func setFrequency(frequency:CGFloat) {
    if receiverStatus == .Connected {
      soapyReceiver.setFreq(Float(frequency))
    }
  }
  
  override func getFrequency() -> CGFloat {
    return CGFloat(soapyReceiver.getFreq())
  }
  
  override func getAmp1Title() -> String {
    return soapyReceiver.getGainName(0)
  }
  
  override func getAmp1Max() -> Int {
    return Int(soapyReceiver.getGainMax(0))
  }
  
  override func getAmp1Val() -> Int {
    return Int(soapyReceiver.getGain(0))
  }
  
  override func setAmp1Val(val:Int) {
    let gain = val // 8db steps
    soapyReceiver.setGain(Int32(gain), index: 0)
    // Save value
    NSUserDefaults.standardUserDefaults().setInteger(gain, forKey: receiverName+"AMP1")
  }
  
  override func getAmp2Title() -> String {
    return soapyReceiver.getGainName(1)
  }
  
  override func getAmp2Max() -> Int {
    return Int(soapyReceiver.getGainMax(1))
  }
  
  override func getAmp2Val() -> Int {
    return Int(soapyReceiver.getGain(1))
  }
  
  override func setAmp2Val(val:Int) {
    let gain = val  // 2db steps
    soapyReceiver.setGain(Int32(gain), index: 1)
    // Save value
    NSUserDefaults.standardUserDefaults().setInteger(gain, forKey: receiverName+"AMP2")
  }
  
  override func loadSettings() {
    if NSUserDefaults.standardUserDefaults().objectForKey(receiverName+"AMP1") != nil {
      let gain1 = NSUserDefaults.standardUserDefaults().integerForKey(receiverName+"AMP1")
      soapyReceiver.setGain(Int32(gain1), index: 0)
    }
    if NSUserDefaults.standardUserDefaults().objectForKey(receiverName+"AMP2") != nil {
      let gain2 = NSUserDefaults.standardUserDefaults().integerForKey(receiverName+"AMP2")
      soapyReceiver.setGain(Int32(gain2), index: 1)
    }
  }
  
  func dataDidReceived(buf:UnsafeMutablePointer<Float>, length bufLen:Int32) {  
  }
}

class SDRPlayReceiverModel: SoapyReceiverModel {
  
  override init() {
    super.init()
    sampleRate = 8000000
    maximumFreqShift = 1000000
    switchTimeInBlocks = 5
    switchTimeInBlocksFast = 2
    receiver = RecieverType.SDRPlay
    receiverName = RecieverType.SDRPlay.rawValue
    receiverLibrary = "libsdrPlaySupport"
  }
  
  var floats:[Float] = []
  
  override func dataDidReceived(buf:UnsafeMutablePointer<Float>, length bufLen:Int32) {
    floats = [Float](count:Int(bufLen), repeatedValue: 0)
    let k:Float = 128
    // Convert to float
    for p in 0..<Int(bufLen/2) {
      // Reverce I-Q
      floats[2*p] = Float(k*buf[2*p])
      floats[2*p+1] = Float(k*buf[2*p+1])
    }
    if let delegate = self.delegate {
      delegate.onDataDidReceived(UnsafeMutablePointer(floats), count: floats.count)
    }
  }
}

class HackRFReceiverModel: SoapyReceiverModel {
  
  override init() {
    super.init()
    sampleRate = 16000000
    maximumFreqShift = 4000000
    switchTimeInBlocks = 4
    switchTimeInBlocksFast = 2
    receiver = RecieverType.HackRF
    receiverName = RecieverType.HackRF.rawValue
    receiverLibrary = "libHackRFSupport"
  }
  
  var floats:[Float] = []
  
  override func dataDidReceived(buf:UnsafeMutablePointer<Float>, length bufLen:Int32) {
    floats = [Float](count:Int(bufLen), repeatedValue: 0)
    let k:Float = 128
    // Convert to float
    for p in 0..<Int(bufLen/2) {
      // Reverce I-Q
      floats[2*p] = Float(k*buf[2*p])
      floats[2*p+1] = Float(k*buf[2*p+1])
    }
    if let delegate = self.delegate {
      delegate.onDataDidReceived(UnsafeMutablePointer(floats), count: floats.count)
    }
  }
}

class RTLSDRReceiverModel: SoapyReceiverModel {
  
  override init() {
    super.init()
    sampleRate = 3200000
    maximumFreqShift = 1000000
    switchTimeInBlocks = 100
    receiver = RecieverType.RTLSDR
    receiverName = RecieverType.RTLSDR.rawValue
    receiverLibrary = "librtlsdrSupport"
  }
  
  var floats:[Float] = []
  
  override func dataDidReceived(buf:UnsafeMutablePointer<Float>, length bufLen:Int32) {
    floats = [Float](count:Int(bufLen), repeatedValue: 0)
    let k:Float = 2048
    // Convert to float
    for p in 0..<Int(bufLen/2) {
      // Reverce I-Q
      floats[2*p] = Float(k*buf[2*p])
      floats[2*p+1] = Float(k*buf[2*p+1])
    }
    if let delegate = self.delegate {
      delegate.onDataDidReceived(UnsafeMutablePointer(floats), count: floats.count)
    }
  }
}


