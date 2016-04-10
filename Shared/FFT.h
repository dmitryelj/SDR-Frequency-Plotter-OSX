//
//  FFT.h
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 18/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFT : NSObject

- (void)doFFT:(float*)dataIn dataOut:(float*)dataOut count:(int)count;

@end
