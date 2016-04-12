//
//  SoapyReceiverImpl.m
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 04/04/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

#import "SoapyReceiverImpl.h"
#include "SoapySDR/Modules.hpp"
#include "SoapySDR/Device.hpp"
#include "SoapySDR/Constants.h"

@implementation SoapyReceiverImpl
{
  std::string module;
  SoapySDR::Device *soapyDevice;
  SoapySDR::Kwargs deviceArgs;
  int sampleRate;
  SoapySDR::Stream *stream;
  size_t streamMTU;
  BOOL modeRX;
  bool terminated;
  void *buffs[1];
  std::vector<std::string> gainNames;
  std::vector<int> gainMaximums;
}

-(id)init {
  if ( self = [super init] ) {
    module = "";
    soapyDevice = nil;
    stream = nil;
    modeRX = false;
    terminated = false;
    buffs[0] = nil;
  }
  return self;
}


- (int)initLib:(int)samplerate library:(NSString*)library {
  if (soapyDevice != nil) {
    return EXIT_SUCCESS;
  }
  
  NSLog(@"initLib");
  
  terminated = false;
  
  std::vector<std::string> moduless = SoapySDR::listModules();
  // Find module from the list
  module = "";
  for (size_t i = 0; i < moduless.size(); i++) {
    NSString *item = [NSString stringWithCString:moduless[i].c_str() encoding:NSASCIIStringEncoding].lowercaseString;
    if ([item rangeOfString:library.lowercaseString].location != NSNotFound) {
      module = moduless[i];
      break;
    }
  }
  
  if (module.length() == 0) {
    NSLog(@"Receiver %@ not found", library);
    return EXIT_FAILURE;
  }
  
  std::string loadResult = SoapySDR::loadModule(module);
  NSLog(@"loadModule: '%s'", loadResult.c_str());
  if (loadResult.length() > 0) {
    NSLog(@"LoadModule message: %s", loadResult.c_str());
  }
  
  // Enumerate devices
  std::vector<SoapySDR::Kwargs> devices = SoapySDR::Device::enumerate();
  NSLog(@"enumerate: %lu params", devices.size());
  if (devices.size() == 0) {
    NSLog(@"%@: receiver not found", library);
    SoapySDR::unloadModule(module);
    return EXIT_FAILURE;
  }
  
  if (devices.size() > 0) {
    // One device in this version
    deviceArgs = devices[0];
    
    sampleRate = samplerate;
    
    for (SoapySDR::Kwargs::const_iterator it = deviceArgs.begin(); it != deviceArgs.end(); ++it) {
      NSLog(@"%s - %s", it->first.c_str(), it->second.c_str());
      //        std::cout << "  " << it->first << " = " << it->second << std::endl;
      //        if (it->first == "driver") {
      //          dev->setDriver(it->second);
      //        } else if (it->first == "label" || it->first == "device") {
      //          dev->setName(it->second);
      //        }
    }
    
    soapyDevice = SoapySDR::Device::make(deviceArgs);
    size_t channel = 0;
    int direction = 0;
    std::vector<double> sampleRates = soapyDevice->listSampleRates(direction, channel);
    
    gainNames = soapyDevice->listGains(direction, channel);
    gainMaximums.clear();
    for (std::vector<std::string>::iterator gname = gainNames.begin(); gname!= gainNames.end(); gname++) {
      SoapySDR::Range r = soapyDevice->getGainRange(direction, channel, (*gname));
      
      NSLog(@"'%s' range: %f - %f", (*gname).c_str(), r.minimum(), r.maximum());
      gainMaximums.push_back((int)r.maximum());
    }
    
    // Gains test:
    
    SoapySDR::ArgInfoList settingsInfo = soapyDevice->getSettingInfo();
    SoapySDR::ArgInfoList::const_iterator settings_i;
    for (settings_i = settingsInfo.begin(); settings_i != settingsInfo.end(); settings_i++) {
      SoapySDR::ArgInfo setting = (*settings_i);
      std::string s = soapyDevice->readSetting(setting.key);
      
      NSLog(@"Setting: %s", s.c_str());
      
      //        if ((settingChanged.find(setting.key) != settingChanged.end()) && (settings.find(setting.key) != settings.end())) {
      //          device->writeSetting(setting.key, settings[setting.key]);
      //          settingChanged[setting.key] = false;
      //        } else {
      //          settings[setting.key] = device->readSetting(setting.key);
      //          settingChanged[setting.key] = false;
      //        }
    }
  }
  

  return EXIT_SUCCESS;
}

- (void)closeLib {
  if (soapyDevice != nil) {
    SoapySDR::Device::unmake(soapyDevice);
    soapyDevice = nil;
  }
  if (buffs[0] != nil) {
    free(buffs[0]);
    buffs[0] = nil;
  }
  if (module.length() > 0) {
    SoapySDR::unloadModule(module);
    module = "";
  }
  
  NSLog(@"closeLib");
}

- (int)gainsCount {
  return (int)gainNames.size();
}

- (NSString*)getGainName:(int)index {
  if (index >= 0 && index < gainNames.size()) {
    return [NSString stringWithFormat:@"%s (0-%d)", gainNames[index].c_str(), gainMaximums[index]];
  }
  return @"-";
}

- (int)getGainMax:(int)index {
  if (index >= 0 && index < gainMaximums.size()) {
    return gainMaximums[index];
  }
  return 0;
}

- (void)setGain:(int)gain index:(int)index {
  if (soapyDevice != nil && index >= 0 && index < gainNames.size()) {
    size_t channel = 0;
    int direction = 0;
    std::string gainName = gainNames[index];
    soapyDevice->setGain(direction, channel, gainName, (double)gain);
  }
}

- (int)getGain:(int)index {
  if (soapyDevice != nil && index >= 0 && index < gainNames.size()) {
    size_t channel = 0;
    int direction = 0;
    std::string gainName = gainNames[index];
    return (int)soapyDevice->getGain(direction, channel, gainName);
  }
  return 0;
}

- (int)startRX {
  if (soapyDevice == nil) {
    return EXIT_FAILURE;
  }
  
//  size_t channel = 0;
//  int direction = 0;
//  bool automatic = false;
//  soapyDevice->setGainMode(direction, channel, automatic);
  
  stream = soapyDevice->setupStream(SOAPY_SDR_RX, "CF32", std::vector<size_t>(), deviceArgs);
  
  streamMTU = soapyDevice->getStreamMTU(stream);
  
  
  buffs[0] = malloc(streamMTU * 4 * sizeof(float));
  
  soapyDevice->setSampleRate(SOAPY_SDR_RX, 0, sampleRate);
  soapyDevice->activateStream(stream);
  
  terminated = false;
  modeRX = true;
  
  __unsafe_unretained SoapyReceiverImpl *self_ = self;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    while (1) {
      long long timeNs;
      int flags;
      size_t mtElems = streamMTU;
      int n_stream_read = soapyDevice->readStream(stream, buffs, mtElems, flags, timeNs);
      if (n_stream_read > 0 && self_.delegate != nil) {
      
        if (self_ != nil && self_.delegate != nil && self_->terminated == false)
          [self_.delegate dataDidReceived:(float*)buffs[0] length:n_stream_read];
      }
      //NSLog(@"n_stream_read: %d", n_stream_read);
      
      if (self_->terminated) {
        break;
      }
    }
    [self_ closeStream];
  });

  return EXIT_SUCCESS;
}

- (void)closeStream {
  modeRX = false;
  soapyDevice->deactivateStream(stream);
  soapyDevice->closeStream(stream);
  
  NSLog(@"closeStream");
}

- (int)stopRX {
  if (soapyDevice == nil) {
    return EXIT_FAILURE;
  }

  terminated = true;
  return EXIT_SUCCESS;
}

- (BOOL)isModeRX {
  return modeRX;
}

- (void)setFreq:(float)frequency {
  if (soapyDevice != nil) {
    soapyDevice->setFrequency(SOAPY_SDR_RX, 0, "RF", (double)frequency);
  }
}

- (double)getFreq {
  if (soapyDevice != nil) {
    return soapyDevice->getFrequency(SOAPY_SDR_RX, 0, "RF");
  }
  return 0;
}

@end
