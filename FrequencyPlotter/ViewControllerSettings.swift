//
//  ViewControllerSettings.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 21/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

import Cocoa

class ViewControllerSettings: NSViewController {

  @IBOutlet weak var labelGain1: NSTextField!
  @IBOutlet weak var sliderGain1: NSSlider!
  @IBOutlet weak var labelGain2: NSTextField!
  @IBOutlet weak var sliderGain2: NSSlider!
  var titleGain1:String = ""
  var valueGain1:CGFloat = 0
  var valueGain1Low:CGFloat = 0
  var valueGain1High:CGFloat = 100
  var titleGain2:String = ""
  var valueGain2:CGFloat = 0
  var valueGain2Low:CGFloat = 0
  var valueGain2High:CGFloat = 100
  var onDidChangedGain1: ((CGFloat) -> Void)?
  var onDidChangedGain2: ((CGFloat) -> Void)?

  override func viewDidLoad() {
      super.viewDidLoad()
    
    labelGain1.stringValue = titleGain1
    sliderGain1.minValue = Double(valueGain1Low)
    sliderGain1.maxValue = Double(valueGain1High)
    sliderGain1.floatValue = Float(valueGain1)
    labelGain2.stringValue = titleGain2
    sliderGain2.minValue = Double(valueGain2Low)
    sliderGain2.maxValue = Double(valueGain2High)
    sliderGain2.floatValue = Float(valueGain2)
  }
  
  @IBAction func onSliderGain1ValueChanged(sender: AnyObject) {
    let val = CGFloat(sliderGain1.floatValue)
    if let ch = onDidChangedGain1 {
      ch(val)
    }
  }
    
  @IBAction func onSliderGain2ValueChanged(sender: AnyObject) {
    let val = CGFloat(sliderGain2.floatValue)
    if let ch = onDidChangedGain2 {
      ch(val)
    }
  }
}
