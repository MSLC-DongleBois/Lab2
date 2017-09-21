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
//buffer size of 8192 best fit for sub 6Hz accuracy
#define BUFFER_SIZE 8192
#define NUM_PEAKS 2

@interface FreqViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) NSMutableArray *magArray;
@end

@implementation FreqViewController

@synthesize magArray = _magArray;

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

-(NSMutableArray*) magArray
{
    if(!_magArray)
    {
        _magArray = [[NSMutableArray alloc] initWithCapacity:NUM_PEAKS];
    }
    
    return _magArray;
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
    
    [NSTimer scheduledTimerWithTimeInterval:.5
                                     target:self
                                   selector:@selector(continuousFFT:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) continuousFFT: (NSTimer*) t
{
    [self getNewFFT];
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
    
    //NSLog(@"%f", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE)));
    
    NSInteger peaks = 0;

//    for (int i = 1; i < (BUFFER_SIZE/2) - 1; i++)
//    {
//        // here, we're checking for a center peak
//        if (fftMagnitude[i] > fftMagnitude[i - 1] && fftMagnitude[i] > fftMagnitude[i + 1])
//        {
//            // if there are fewer than two peaks in the array, add a peak
//            if (peaks < 2)
//            {
//                [self.magArray addObject:[NSNumber numberWithFloat:fftMagnitude[i]]];
//                ++peaks;
//            }
//
//            // once there are two peaks in the array, we have to see whether our current peak
//            // is big enough to replace a peak in the array
//            else
//            {
//                float smallestVal = FLT_MAX;
//                int indexAt = -1;
//                for (int j = 0; j < NUM_PEAKS; j++)
//                {
//                    // find the index of the smallest peak
//                    if ([[self.magArray objectAtIndex:j] floatValue] < smallestVal)
//                    {
//                        smallestVal = [[self.magArray objectAtIndex:j] floatValue];
//                        indexAt = j;
//                    }
//                }
//
//                // Check to see if our current peak is larger than the smallest value.
//                if (fftMagnitude[i] > [[self.magArray objectAtIndex:indexAt] floatValue])
//                {
//                    // if it is, replace it.
//                    //[self.magArray insertObject:[NSNumber numberWithFloat:fftMagnitude[i]] atIndex:indexAt];
//                    [self.magArray replaceObjectAtIndex:indexAt withObject:[NSNumber numberWithFloat:fftMagnitude[i]]];
//                }
//
//            }
//        }
//
//    }

    _Freq1Label.text = [NSString stringWithFormat:@"%.2f", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    _Freq2Label.text = [NSString stringWithFormat:@"%.2f", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    
//    _Freq1Label.text = [NSString stringWithFormat:@"%.2f", ([[self.magArray objectAtIndex:0] floatValue] * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
//
//    _Freq2Label.text = [NSString stringWithFormat:@"%.2f", ([[self.magArray objectAtIndex:1] floatValue] * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    
    free(arrayData);
    free(fftMagnitude);
}


@end
