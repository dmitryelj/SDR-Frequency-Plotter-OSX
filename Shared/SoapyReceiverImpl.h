//
//  SoapyReceiverImpl.h
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 04/04/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//  dmitryelj@gmail.com

#import <Foundation/Foundation.h>

@protocol SoapyReceiverImplDelegate <NSObject>

- (void)dataDidReceived:(float*)buf length:(int)bufLen;

@end


@interface SoapyReceiverImpl : NSObject

- (int)initLib:(int)samplerate library:(NSString*)library;
- (void)closeLib;

- (int)startRX;
- (int)stopRX;
- (BOOL)isModeRX;

- (void)setFreq:(float)frequency;
- (double)getFreq;

- (int)gainsCount;
- (NSString*)getGainName:(int)index;
- (int)getGainMax:(int)index;
- (void)setGain:(int)gain index:(int)index;
- (int)getGain:(int)index;

@property (nonatomic, weak) id <SoapyReceiverImplDelegate> delegate;

@end
