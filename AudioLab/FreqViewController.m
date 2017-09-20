//
//  FreqViewController.m
//  AudioLab
//
//  Created by Logan Dorsey on 9/17/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

#import "FreqViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

//buffer must be a power of two
#define BUFFER_SIZE 8192

@interface FreqViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@end

@implementation FreqViewController

#pragma mark Lazy Instantiation
-(Novocaine*)audioManager
{
    if(!_audioManager)
    {
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer
{
    if(!_buffer)
    {
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(FFTHelper*)fftHelper
{
    if(!_fftHelper)
    {
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}

#pragma mark VC Life Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    __block FreqViewController * __weak  weakSelf = self;
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
    {
        if(numChannels > 1) {
            float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
            for(int i =numFrames*numChannels; i>=0;i-=2) {
                arrayData[i/2] = data[i];
            }
            [weakSelf.buffer addNewFloatData:arrayData withNumSamples:numFrames];
            free(arrayData);
        }
        else {
            [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        }
    }];
    
    [self.audioManager play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) getNewFFT
{
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    [self.fftHelper performForwardFFTWithData:arrayData andCopydBMagnitudeToBuffer:fftMagnitude];
    
    float maxVal = 0.0;
    vDSP_Length indexLoc = 0;
    vDSP_maxvi(fftMagnitude, 1, &maxVal, &indexLoc, BUFFER_SIZE/2);
    
    _Freq1Label.text = [NSString stringWithFormat:@"%.2f", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    
    
    free(arrayData);
    free(fftMagnitude);
}
- (IBAction)buttonPressed:(id)sender {
    
    [self getNewFFT];
}

@end
