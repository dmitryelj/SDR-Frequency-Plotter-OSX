//
//  FFT.m
//  SpectrumGraph
//
//  Created by Dmitrii Eliuseev on 18/03/16.
//  Copyright © 2016 Dmitrii Eliuseev. All rights reserved.
//

#import "FFT.h"

#define MAX_FFT 16384

@implementation FFT
{
  float *pData;
}

-(id)init {
  if ( self = [super init] ) {
    pData = malloc(MAX_FFT*sizeof(float));
  }
  return self;
}

- (void)dealloc {
  free(pData);
  pData = nil;
}

- (void)doFFT:(float*)dataIn dataOut:(float*)dataOut count:(int)count {
  // Set data
  for(int p=0; p<count; p++) {
    float f = 0.54 + 0.46*cos(2*M_PI*p/(count - 1)); // Hamming window
    pData[2*p+1] = dataIn[2*p+1]*f;
    pData[2*p+2] = dataIn[2*p]*f;
  }
  // FFT
  four1(pData, count, 1);
  // Result
  for(int p=0; p<count; p++) {
    float re = pData[2*p+1], im = pData[2*p+2];
    float val = sqrt(re*re + im*im);
    dataOut[p] = val; //100*log10f(val);
  }
  // Remove zero peak
  dataOut[0] = (dataOut[2] + dataOut[3])/2;
  dataOut[1] = (dataOut[3] + dataOut[4])/2;
  //dataOut[2] = 0;
  //dataOut[3] = 0;
}

/*
 FFT/IFFT routine. (see pages 507-508 of Numerical Recipes in C)
 
 Inputs:
	data[] : array of complex* data points of size 2*NFFT+1.
 data[0] is unused,
 * the n'th complex number x(n), for 0 <= n <= length(x)-1, is stored as:
 data[2*n+1] = real(x(n))
 data[2*n+2] = imag(x(n))
 if length(Nx) < NFFT, the remainder of the array must be padded with zeros
 
	nn : FFT order NFFT. This MUST be a power of 2 and >= length(x).
	isign:  if set to 1,
 computes the forward FFT
 if set to -1,
 computes Inverse FFT - in this case the output values have
 to be manually normalized by multiplying with 1/NFFT.
 Outputs:
	data[] : The FFT or IFFT results are stored in data, overwriting the input.
*/

void four1(float data[], int nn, int isign)
{
  int n, mmax, m, j, istep, i;
  float wtemp, wr, wpr, wpi, wi, theta;
  float tempr, tempi;
  
  n = nn << 1;
  j = 1;
  for (i = 1; i < n; i += 2) {
    if (j > i) {
      tempr = data[j];     data[j] = data[i];     data[i] = tempr;
      tempr = data[j+1]; data[j+1] = data[i+1]; data[i+1] = tempr;
    }
    m = n >> 1;
    while (m >= 2 && j > m) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }
  mmax = 2;
  while (n > mmax) {
    istep = 2*mmax;
    theta = 2.0*M_PI/(isign*mmax);
    wtemp = sin(0.5*theta);
    wpr = -2.0*wtemp*wtemp;
    wpi = sin(theta);
    wr = 1.0;
    wi = 0.0;
    for (m = 1; m < mmax; m += 2) {
      for (i = m; i <= n; i += istep) {
        j =i + mmax;
        tempr = wr*data[j]   - wi*data[j+1];
        tempi = wr*data[j+1] + wi*data[j];
        data[j]   = data[i]   - tempr;
        data[j+1] = data[i+1] - tempi;
        data[i] += tempr;
        data[i+1] += tempi;
      }
      wr = (wtemp = wr)*wpr - wi*wpi + wr;
      wi = wi*wpr + wtemp*wpi + wi;
    }
    mmax = istep;
  }
}

@end
