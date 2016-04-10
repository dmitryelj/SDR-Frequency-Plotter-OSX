//
//  SignalProcessing.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//

import Cocoa
import Accelerate

class SignalProcessing: NSObject {

  // FFT Processing
  
//  private var fftSize_ = 1024
//  var fftSize:Int {
//    get {
//      return fftSize_
//    }
//    set {
//      fftSize_ = newValue
//    }
//  }
  var fftResults:[Float] = [Float](count: 16384, repeatedValue:0)
  let fft = FFT()
  
  func processFFT(points: UnsafeMutablePointer<Float>, count: Int, fftSize: Int) -> UnsafeMutablePointer<Float> {
    
    // Do FFT
    fft.doFFT(points, dataOut:UnsafeMutablePointer(fftResults), count: Int32(fftSize))
    
//    var dataIn:[Float] = []
//    for i in 0..<fftSize {
//      dataIn.append(points[i])
//    }
//    let result = fft(dataIn)
//    // Use right part of FFT
//    for i in 0..<result.count/2 {
//        fftResults[i] = result[result.count/2 + i]
//    }
    
    return UnsafeMutablePointer(fftResults)
  }
  
  // Save scanning results
  
  var pos = 0
  var resultsData:[Float] = []
  
  private var dataStorage:[Float] = [] // Storage for avegare
  private var dataBlocks = 0
  
  func clearData() {
    pos = 0
    dataBlocks = 0
    resultsData = []
    dataStorage = []
  }
  
  func addData(points: UnsafeMutablePointer<Float>, count: Int) {
    if dataStorage.count == 0 {
      dataStorage = [Float](count: count, repeatedValue:0)
      dataBlocks = 0
    }
    
    for i in 0..<count {
      dataStorage[i] += points[i]
    }
    dataBlocks += 1
  }
  
  func pushNextBlock() {
    // Add calculated average to the main block
    for i in 0..<dataStorage.count {
      resultsData.append(dataStorage[i]/Float(dataBlocks))
    }
    dataStorage.removeAll()
    dataBlocks = 0
  }
  
  // Results
  
  func prepareResultImage() -> NSImage {
    let width = CGFloat(max(1, resultsData.count)), height:CGFloat = 400
    let img = NSImage(size: CGSizeMake(width, height))
    img.lockFocus()
    NSColor.redColor().setFill()
    NSColor.redColor().setStroke()
    //NSBezierPath.fillRect(NSMakeRect(0, 0, 25, 25))
    for p in 0..<resultsData.count {
      var data = resultsData[p].isNaN ? 1 : CGFloat(resultsData[p])
      if data < 0 { data = 0 }
      if (data > height) { data = height }
      NSBezierPath.strokeLineFromPoint(NSPoint(x: CGFloat(p), y: 10), toPoint: NSPoint(x: CGFloat(p), y: 10 + data))
    }
    // Text marks
    let m1:NSString = "1"
    m1.drawAtPoint(NSPoint(x: 0, y: 0), withAttributes: [ NSFontAttributeName : NSFont.systemFontOfSize(16) , NSForegroundColorAttributeName : NSColor.redColor()])
    img.unlockFocus()
    return img
  }
  
  // Helpers
  
  func fft(input: [Float]) -> [Float] {
    // Source: https://github.com/mattt/Surge/blob/master/Source/FFT.swift
    var real = [Float](input)
    var imaginary = [Float](count: input.count, repeatedValue: 0.0)
    var splitComplex = DSPSplitComplex(realp: &real, imagp: &imaginary)
    
    let length = vDSP_Length(floor(log2(Float(input.count))))
    let radix = FFTRadix(kFFTRadix2)
    
    let weights = vDSP_create_fftsetup(length, radix)
    vDSP_fft_zip(weights, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
    
    var magnitudes = [Float](count: input.count, repeatedValue: 0.0)
    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
    
    var normalizedMagnitudes = [Float](count: input.count, repeatedValue: 0.0)
    vDSP_vsmul(sqrtF(magnitudes), 1, [2.0 / Float(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
    
    vDSP_destroy_fftsetup(weights)
    
    return normalizedMagnitudes
  }
    
  func sqrtF(x: [Float]) -> [Float] {
    var results = [Float](count: x.count, repeatedValue: 0.0)
    vvsqrtf(&results, x, [Int32(x.count)])
    
    return results
  }
  
  func sqrtD(x: [Double]) -> [Double] {
    var results = [Double](count: x.count, repeatedValue: 0.0)
    vvsqrt(&results, x, [Int32(x.count)])
    
    return results
  }
}
