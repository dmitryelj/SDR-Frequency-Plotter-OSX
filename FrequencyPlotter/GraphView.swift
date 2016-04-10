//
//  GraphView.swift
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 15/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

import Cocoa

class GraphView: NSView {

  var points = [Float](count: 32768, repeatedValue:0)
  var pointsLayer2 = [Float](count: 32768, repeatedValue:0)
  // Draw ticks on graph
  var fftSize:Int32 = 0
  var sampleRate:Int32 = 1
  var freqStart:CGFloat = 0
  var gain:CGFloat = 1
  var shift:CGFloat = 0
  
  let backColor = NSColor(white: 20.0/255.0, alpha:1)
  let ticksColor = NSColor(white: 120.0/255.0, alpha:1)
  let lineColor = NSColor(white: 70.0/255.0, alpha:1)
  let dataColor1 = NSColor(red: 0, green: 0.7, blue: 0, alpha: 1)
  let dataColor2 = NSColor(red: 0.7, green: 0, blue: 0, alpha: 1)
  let textColor = NSColor(red: 0.8, green: 0, blue: 0, alpha: 1)
  let textFont  = NSFont.systemFontOfSize(12)
  
  func clearData() {
    for p in 0..<points.count {
      points[p] = 0
    }
  }
  
  func switchLayer() {
    let cnt = min(points.count, pointsLayer2.count)
    for p in 0..<cnt {
      let v = points[p]
      points[p] = pointsLayer2[p]
      pointsLayer2[p] = v
    }
  }
  
  override func drawRect(dirtyRect: NSRect) {
    super.drawRect(dirtyRect)
    
    let back = NSBezierPath(rect: self.bounds)
    backColor.setFill()
    back.fill()
    
    // Ticks
    
    var tickF:Int32 = 1000000     // KHz
    var tick = Int(Int64(tickF)*Int64(fftSize)/Int64(sampleRate))
    // Adjust for different scales
    if tick < 10 {
      tickF = 10000000
      tick = Int(Int64(tickF)*Int64(fftSize)/Int64(sampleRate))
    }
    if tick < 20 {
      tickF = 5000000
      tick = Int(Int64(tickF)*Int64(fftSize)/Int64(sampleRate))
    }
   if tick < 40 {
      tickF = 2000000
      tick = Int(Int64(tickF)*Int64(fftSize)/Int64(sampleRate))
    }
    let tick_f = CGFloat(tickF)*CGFloat(fftSize)/CGFloat(sampleRate)
    //let steps = 1 //tick < 10 ? 20 : 5
    let line1 = NSBezierPath()
    let line2 = NSBezierPath()
    let maxX = self.bounds.size.width
    for p in 0..<Int(self.bounds.size.width) {
      // Big marks
      let px = tick_f*CGFloat(p)*CGFloat(0.1)
      if px <= maxX {
        if (p%10) == 0 {
          line2.moveToPoint(NSMakePoint(CGFloat(round(px)), 4))
          line2.lineToPoint(NSMakePoint(CGFloat(round(px)), dirtyRect.size.height))
          // Text
          let freq = freqStart + CGFloat(tickF/10)*CGFloat(p) //CGFloat(p/tick)
          let m1:NSString = String(format:"%.1fM", freq/1.M)
          m1.drawAtPoint(NSPoint(x: px, y: 0), withAttributes: [ NSFontAttributeName : textFont, NSForegroundColorAttributeName : textColor ])
        } else
        {
          let len:CGFloat = (p % 5) == 0 ? 10 : 5
          line1.moveToPoint(NSMakePoint(CGFloat(round(px)), 22))
          line1.lineToPoint(NSMakePoint(CGFloat(round(px)), 22 - len))
        }
      }
    }
    ticksColor.setStroke()
    line1.lineWidth = 1
    line1.stroke()
    
    lineColor.setStroke()
    line2.lineWidth = 1
    line2.stroke()
    
    drawData(dirtyRect, array:pointsLayer2, color:dataColor2)
    drawData(dirtyRect, array:points, color:dataColor1)
  }
  
  func drawData(dirtyRect: NSRect, array:[Float], color:NSColor) {
    
    color.setStroke()
    let shiftPx = 0

    let line2 = NSBezierPath()
    let maxY = dirtyRect.size.height - 2
    for p in 0..<Int(self.bounds.size.width) {
      var data = p<array.count ? array[p].isNaN ? 1 : shift + gain*CGFloat(array[p]) : 0
      if data < 0 { data = 0 }
      if (data > maxY) { data = maxY }
      line2.moveToPoint(NSMakePoint(CGFloat(shiftPx + p), 22))
      line2.lineToPoint(NSMakePoint(CGFloat(shiftPx + p), 22 + data))
      
    }
    line2.lineWidth = 2
    line2.stroke()
  }
}
