//
//  ViewController.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

import Cocoa

class ViewController: NSViewController, NSWindowDelegate, NSComboBoxDataSource, ReceiverModelDelegate {

  @IBOutlet weak var comboReceiverSelect: NSComboBox!
  @IBOutlet weak var textFrequencyStart: NSTextField!
  @IBOutlet weak var textFrequencyEnd: NSTextField!
  @IBOutlet weak var labelEstimatedSize: NSTextField!
  @IBOutlet weak var comboResolutionSelect: NSComboBox!
  @IBOutlet weak var labelFrequency: NSTextField!
  @IBOutlet weak var textFieldFrequency: NSTextField!
  @IBOutlet weak var buttonStartStop: NSButton!
  @IBOutlet weak var scrollResultView: NSScrollView!
  @IBOutlet weak var progressView: NSLevelIndicator!
  @IBOutlet weak var graphPreview: GraphView!
  @IBOutlet weak var buttonSettings: NSButton!
  @IBOutlet weak var checkButtonFastMode: NSButton!
  @IBOutlet weak var checkButtonLoopMode: NSButton!
  @IBOutlet weak var labelScanTime: NSTextField!
  var graphResults = GraphView()
  let tagReceiverSelect = 1
  let tagResolutionSelect = 2
  // Receiver
  var receiverModel:ReceiverModel = HackRFReceiverModel()
  var receivers = [ RecieverType.HackRF, RecieverType.SDRPlay, RecieverType.RTLSDR, RecieverType.Demo ]
  var receiverIndex = 0
  // Sugnal processing
  var signalProcessing = SignalProcessing()
  // Frequency
  var freqCurrent:CGFloat = 87.M
  var freqMin:CGFloat = 87.M
  var freqMax:CGFloat = 108.M
  var isScanning = false
  var fastMode = false
  var loopMode = false
  // Number of frequency resolutions for Combobox (FFT sizes)
  let fftVariants:[Int] = [ 32, 64, 128, 256, 512, 1024, 2048, 4096 ]
  var fftSize  = 512
  let fftPreviewSize = 1024
  let wndRecieverSize:CGFloat = 1.M
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.window?.delegate = self
    
    // Setup
    receiverModel.delegate = self
    let fftSelection = 3
    fftSize = fftVariants[fftSelection]
    graphPreview.fftSize = Int32(fftPreviewSize)
    graphPreview.sampleRate = Int32(receiverModel.sampleRate)
    graphPreview.freqStart = freqCurrent
    graphResults.fftSize = Int32(fftSize)
    graphResults.sampleRate = Int32(receiverModel.sampleRate)
    // Result
    scrollResultView.contentView.documentView = NSView(frame: CGRectMake(0,0,1,1))
    if let view = scrollResultView.contentView.documentView as? NSView {
      graphResults.frame = view.frame
      view.addSubview(graphResults)
    }
    scrollResultView.contentView.backgroundColor = graphResults.backColor
    // Progress
    progressView.minValue = 0
    progressView.maxValue = 100
    progressView.doubleValue = 0
    progressView.levelIndicatorStyle = .DiscreteCapacityLevelIndicatorStyle
    // Combos
    comboReceiverSelect.tag = tagReceiverSelect
    comboReceiverSelect.usesDataSource = true
    comboReceiverSelect.dataSource = self
    comboReceiverSelect.reloadData()
    comboResolutionSelect.tag = tagResolutionSelect
    comboResolutionSelect.usesDataSource = true
    comboResolutionSelect.dataSource = self
    comboResolutionSelect.reloadData()
    comboReceiverSelect.selectItemAtIndex(receiverIndex)
    comboResolutionSelect.selectItemAtIndex(fftSelection)
    // Last used frequencies
    if let freqMin_ = NSUserDefaults.standardUserDefaults().objectForKey("ScanFreqMin") as? String, let f = Float(freqMin_) {
      freqMin = CGFloat(f)*1.M
    }
    if let freqMax_ = NSUserDefaults.standardUserDefaults().objectForKey("ScanFreqMax") as? String, let f = Float(freqMax_) {
      freqMax = CGFloat(f)*1.M
    }
    if let freqSet = NSUserDefaults.standardUserDefaults().objectForKey("FreqCustomSet") as? String {
      textFieldFrequency.stringValue = freqSet
    }
    
    // Gains
    graphPreview.gain = 0.02
    graphResults.gain = 0.5
    
    updateValues()
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.delegate = self
    
    // Show app and version in title
    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
    let version = appDelegate.appVersion()
    view.window?.title = "wnd_title".localized + " v" + version
  }
  
  func windowShouldClose(sender: AnyObject) -> Bool {
    return true
  }
  
  func windowWillClose(notification: NSNotification) {
    receiverModel.stopRX()
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
      self.receiverModel.disconnect()
    }
  }
  
  // MARK: UI
  
  func updateValues() {
    textFrequencyStart.stringValue = String(format: "%.2f", freqMin/1.M)
    textFrequencyEnd.stringValue = String(format: "%.2f", freqMax/1.M)
    labelFrequency.stringValue = String(format: "%.2f %@", freqCurrent/1.M, "mhz".localized)
    let resultSize = calcResultSize()
    labelEstimatedSize.stringValue = String(format: "%dx%d %@", Int(resultSize.width), Int(resultSize.height), "px".localized)
    if isScanning {
      progressView.floatValue = Float(100*(freqCurrent - freqMin)/(freqMax - freqMin))
    } else {
      progressView.floatValue = 0
    }
    graphPreview.setNeedsDisplayInRect(graphPreview.bounds)
  }
  
  func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
    if aComboBox.tag == tagResolutionSelect {
      return fftVariants.count
    }
    if aComboBox.tag == tagReceiverSelect {
      return receivers.count
    }
    return 0
  }
  
  func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
    if aComboBox.tag == tagResolutionSelect && index >= 0 && index < fftVariants.count {
      let fft = fftVariants[index]
      let blockSize = CGFloat(fft)*wndRecieverSize/CGFloat(receiverModel.sampleRate)
      return "\(blockSize) \("pxmb".localized)"
    }
    if aComboBox.tag == tagReceiverSelect && index >= 0 && index < receivers.count{
      let receiver = receivers[index]
      return receiver.rawValue
    }
    return ""
  }
  
  func comboBoxSelectionDidChange(notification: NSNotification) {
    if let c = notification.object as? NSComboBox {
      if c.tag == tagReceiverSelect {
        receiverIndex = c.indexOfSelectedItem
        let receiver = receivers[receiverIndex]
        if receiver == .HackRF {
          receiverModel = HackRFReceiverModel()
        }
        if receiver == .SDRPlay {
          receiverModel = SDRPlayReceiverModel()
        }
        if receiver == .RTLSDR {
          receiverModel = RTLSDRReceiverModel()
        }
        if receiver == .Demo {
          receiverModel = DemoReceiverModel()
        }
        receiverModel.delegate = self
        graphPreview.sampleRate = Int32(receiverModel.sampleRate)
        graphResults.sampleRate = Int32(receiverModel.sampleRate)
        updateValues()
      }
      if c.tag == tagResolutionSelect {
        fftSize = fftVariants[c.indexOfSelectedItem]
        graphResults.fftSize = Int32(fftSize)
        graphResults.clearData()
        if let f1 = Float(textFrequencyStart.stringValue), let f2 = Float(textFrequencyEnd.stringValue) {
          freqMin = CGFloat(f1)*1.M
          freqMax = CGFloat(f2)*1.M
        }
        updateValues()
      }
    }
  }

  override var representedObject: AnyObject? {
    didSet {
      // Update the view, if already loaded.
      NSLog("representedObject")
    }
  }

  @IBAction func onButtonFrequencySet(sender: AnyObject) {
    if isScanning {
      return
    }
    
    if let f = Float(textFieldFrequency.stringValue) {
      freqCurrent = CGFloat(f)*1.M
      receiverModel.setFrequency(freqCurrent)
      graphPreview.freqStart = freqCurrent
      updateValues()
      
      NSUserDefaults.standardUserDefaults().setObject(textFieldFrequency.stringValue, forKey: "FreqCustomSet")
    }
  }
  
  @IBAction func onButtonFrequencyInc(sender: AnyObject) {
    if !isScanning {
      freqCurrent += 250000
      receiverModel.setFrequency(freqCurrent)
      graphPreview.freqStart = freqCurrent
      updateValues()
    }
  }
  
  @IBAction func onButtonFrequencyDec(sender: AnyObject) {
    if !isScanning {
      freqCurrent -= 250000
      receiverModel.setFrequency(freqCurrent)
      graphPreview.freqStart = freqCurrent
      updateValues()
    }
  }
  
  @IBAction func onButtonFastMode(sender: NSButton) {
    fastMode = sender.state == NSOnState
  }
  
  @IBAction func onButtonLoopMode(sender: NSButton) {
    loopMode = sender.state == NSOnState
  }
  
  @IBAction func onButtonScanStart(sender: AnyObject) {
    if isScanning {
      return
    }
    
    if let f1 = Float(textFrequencyStart.stringValue), let f2 = Float(textFrequencyEnd.stringValue) {
      freqMin = CGFloat(f1)*1.M
      freqCurrent = CGFloat(f1)*1.M
      freqMax = CGFloat(f2)*1.M
      updateValues()
      
      // Save values
      NSUserDefaults.standardUserDefaults().setObject(textFrequencyStart.stringValue, forKey: "ScanFreqMin")
      NSUserDefaults.standardUserDefaults().setObject(textFrequencyEnd.stringValue, forKey: "ScanFreqMax")
      NSUserDefaults.standardUserDefaults().synchronize()
      
      if receiverModel.receiverStatus != .Connected {
        let res = receiverModel.connectReceiver()
        if res {
          receiverModel.loadSettings()
          receiverModel.startRX()
          
          buttonStartStop.title = "stop".localized
          comboReceiverSelect.enabled = false
        } else {
          showNoReceiverMessage()
          return
        }
      }
       
      // Set size
      let size = calcResultSize()
      if let v = scrollResultView.contentView.documentView as? NSView {
        v.frame = CGRectMake(0,0,size.width,size.height)
        graphResults.frame = v.frame
      }
      graphResults.points = []
      graphResults.freqStart = freqMin
      startScanning()
    }
  }

  @IBAction func onButtonScanStop(sender: AnyObject) {
    if isScanning {
      stopScanning()
    }
  }
  
  @IBAction func onButtonReceiverStart(sender: AnyObject) {
    if receiverModel.isRX() == false {
      let res = receiverModel.connectReceiver()
      if res {
        receiverModel.startRX()
        receiverModel.loadSettings()
        receiverModel.setFrequency(freqCurrent)
        buttonStartStop.title = "stop".localized
        comboReceiverSelect.enabled = false
      } else {
        showNoReceiverMessage()
      }
    } else {
      if isScanning {
        stopScanning()
      }
      receiverModel.stopRX()

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        self.receiverModel.disconnect()
        self.signalProcessing.clearData()
        self.buttonStartStop.title = "start".localized
        self.comboReceiverSelect.enabled = true
      }
    }
  }
  
  @IBAction func onButtonSave(obj:AnyObject?) {
    let rep = graphResults.bitmapImageRepForCachingDisplayInRect(graphResults.bounds)
    graphResults.cacheDisplayInRect(graphResults.bounds, toBitmapImageRep: rep!)
    
    // Save as png
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
    let date = dateFormatter.stringFromDate(NSDate())
    let fileName = String(format:"Scan-%@-%.1f-%.1f.png", date, freqMin/1.M, freqMax/1.M)
    //let imgData = img.TIFFRepresentation
    //let imgData = repSrc?.TIFFRepresentation
    //let rep = NSBitmapImageRep(data: imgData!)
    let data = rep!.representationUsingType(.NSPNGFileType, properties: [NSImageCompressionFactor:1])!
    
    if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
      let path = NSURL(fileURLWithPath: dir as String).URLByAppendingPathComponent(fileName);
      
      let res = data.writeToFile(path.path!, atomically: false)
      NSLog("Saved: \(res)")
      
      showInfoMessage("information".localized, message: "'\(fileName)' \("was_saved".localized)")
    }
  }
  
  @IBAction func onButtonSwitchLayer(sender: AnyObject) {
    graphResults.switchLayer()
    graphResults.setNeedsDisplayInRect(self.graphResults.bounds)
  }
  
  @IBAction func onButtonReceiverSettings(sender: AnyObject) {
    if receiverModel.receiverStatus != .Connected {
      showInfoMessage("information".localized, message: "receiver_not_started".localized)
      return
    }
    
    let settingsView = storyboard?.instantiateControllerWithIdentifier("ViewControllerSettings") as! ViewControllerSettings
    settingsView.titleGain1 = receiverModel.getAmp1Title()
    settingsView.valueGain1 = CGFloat(receiverModel.getAmp1Val())
    settingsView.valueGain1High = CGFloat(receiverModel.getAmp1Max())
    settingsView.onDidChangedGain1 = { (newVal:CGFloat) in
      self.receiverModel.setAmp1Val(Int(newVal));
    }
    settingsView.titleGain2 = receiverModel.getAmp2Title()
    settingsView.valueGain2 = CGFloat(receiverModel.getAmp2Val())
    settingsView.valueGain2High = CGFloat(receiverModel.getAmp2Max())
    settingsView.onDidChangedGain2 = { (newVal:CGFloat) in
      self.receiverModel.setAmp2Val(Int(newVal));
    }
    
    let popover =  NSPopover()
    popover.contentViewController = settingsView
    popover.behavior = NSPopoverBehavior.Transient
    popover.showRelativeToRect(buttonSettings.frame, ofView: self.view, preferredEdge: .MinY)
  }
  
  func showInfoMessage(title:String, message:String) {
    let myPopup = NSAlert()
    myPopup.messageText = title
    myPopup.informativeText = message
    myPopup.alertStyle = .InformationalAlertStyle
    myPopup.addButtonWithTitle("ok".localized)
    //myPopup.runModal()
    myPopup.beginSheetModalForWindow(self.view.window!, completionHandler: nil)
  }
  
  func showNoReceiverMessage() {
    showInfoMessage("warning".localized, message: "receiver_start_error".localized)
  }
  
  // MARK: Receiver
  
  var skipScanBlocks = 0 // Receiver may need some time to change the frequency

  func calcResultSize() -> CGSize {
    let blockSize = CGFloat(fftSize)*wndRecieverSize/CGFloat(receiverModel.sampleRate)
    let sizeW:CGFloat = blockSize*(freqMax - freqMin)/1.M, sizeH:CGFloat = 600
    return CGSizeMake(sizeW, sizeH)
  }
  
  func connectReceiver() -> Bool {
    if receiverModel.receiverStatus != .Connected {
      return receiverModel.connectReceiver()
    }
    return true
  }
  
  var startTime:NSDate? = nil
  
  func startScanning() {
    if connectReceiver() {
      signalProcessing.clearData()
      graphResults.clearData()
      skipScanBlocks = receiverModel.switchTimeInBlocks
      receiverModel.setFrequency(freqCurrent)
      isScanning = true
      startTime = NSDate()
    } else {
      showNoReceiverMessage()
    }
  }
  
  func stopScanning() {
    isScanning = false
  }
  
  func frequencyShift() {
    freqCurrent += receiverModel.maximumFreqShift
    receiverModel.setFrequency(freqCurrent)
    // Check if done
    if freqCurrent >= freqMax {
      // Calc scanning time
      if let start = startTime {
        let ti = NSDate().timeIntervalSinceDate(start)
        labelScanTime.stringValue = String(format:"%@: %.1fs", "scan_time".localized, ti)
      }
      
      // Finish
      if loopMode == false {
        // Stop
        stopScanning()
      } else {
        // Start again
        graphResults.switchLayer()
        graphResults.setNeedsDisplayInRect(self.graphResults.bounds)
        freqCurrent = freqMin
        startScanning()
      }
    }
    updateValues()
  }
  
  // MARK: UI show results
  
  var displayedBlocks = 0
  var processedBlocks = 0
  var fftAverage:[Float] = [Float](count: 16384, repeatedValue:0)
  var fftAverageNum = 0
  
  func onDataDidReceived(points: UnsafeMutablePointer<Float>, count: Int) {
    let fft = signalProcessing.processFFT(points, count:count, fftSize: fftPreviewSize)
    
    // Add fft results to the average buffer
    for i in 0..<fftPreviewSize/2 {
      self.fftAverage[i] += fft[i]
    }
    fftAverageNum += 1
    
    // Update preview: 1 times of 5
    displayedBlocks += 1
    if displayedBlocks >= 10 {
      displayedBlocks = 0
    
      for i in 0..<fftPreviewSize/2 {
        graphPreview.points[i] = fftAverage[i]/Float(fftAverageNum)
        fftAverage[i] = 0
      }
      fftAverageNum = 0
      
      // Draw on preview
      dispatch_async(dispatch_get_main_queue(),{
        self.graphPreview.setNeedsDisplayInRect(self.graphPreview.bounds)
      })
    }
    
    // Add to scan: 1 times of 10
    let kAverage = fastMode ? 2 : 20
    if isScanning {
      if skipScanBlocks > 0 {
        skipScanBlocks -= 1
        return
      }
      
      let fft = signalProcessing.processFFT(points, count:count, fftSize: fftSize)
      
      // Block size, we move shift
      let blockSize = Int(receiverModel.maximumFreqShift*CGFloat(fftSize)/CGFloat(receiverModel.sampleRate))
      let zeroShift = 0 //signalProcessing.fftSize/32 // Ignore zero peak frequency
      signalProcessing.addData(fft+zeroShift, count: blockSize)
      
      processedBlocks += 1
      if processedBlocks >= kAverage {
        processedBlocks = 0
        
        signalProcessing.pushNextBlock()
        // Skip some blocks to allow receiver to change frequency
        skipScanBlocks = fastMode ? receiverModel.switchTimeInBlocksFast : receiverModel.switchTimeInBlocks
        // Draw results and change frequency
        dispatch_async(dispatch_get_main_queue(),{
          self.graphResults.points = self.signalProcessing.resultsData
          self.graphResults.setNeedsDisplayInRect(self.graphResults.bounds)
          self.frequencyShift()
        })
      }
    }
  }
}

