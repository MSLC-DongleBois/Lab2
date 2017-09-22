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
@property (nonatomic) float peak1;
@property (nonatomic) float peak2;
@property (nonatomic) BOOL freqLocked;
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
    
    [NSTimer scheduledTimerWithTimeInterval:.1
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

- (IBAction)getLockState:(UISwitch *)sender {
    self.freqLocked = sender.isOn;
    return;
}


- (void) getNewFFT
{
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    [self.fftHelper performForwardFFTWithData:arrayData andCopydBMagnitudeToBuffer:fftMagnitude];
    
    float currentMax = fftMagnitude[0];
    int idx1 = 0;
    int idx2 = 0;

    // window value of 3
    for (int i = 1; i < ((BUFFER_SIZE/2) - 1); i++)
    {
        if (fftMagnitude[i] > currentMax && fftMagnitude[i-1] < fftMagnitude[i] && fftMagnitude[i+1] < fftMagnitude[i])
        {
            currentMax = fftMagnitude[i];
            idx1 = i;
        }
    }

    currentMax = fftMagnitude[0];

    // window value of 3
    for (int i = 1; i < ((BUFFER_SIZE)/2) - 1; i++)
    {
        if (fftMagnitude[i] > currentMax && fftMagnitude[i-1] < fftMagnitude[i] && fftMagnitude[i+1] < fftMagnitude[i])
        {
            int poss = i;
            int dist = idx1 - poss;
            
            // Calcuate the distance between two peaks. It has to be at least 8 bins/indices apart.
            if (dist > 8)
            {
                currentMax = fftMagnitude[i];
                idx2 = poss;
            }
        }
    }
    
    
    float buff = (float)BUFFER_SIZE;
    float rate = (float)self.audioManager.samplingRate;

    float first, second;
    
    first = ((idx1 * rate)/buff);
    second = ((idx2 * rate)/buff);
    
    // If the frequency lock is ON
    if (self.freqLocked)
    {
        if (first > self.peak1) {
            self.peak1 = first;
            _Freq1Label.text = [NSString stringWithFormat:@"%.2f Hz", first];
        }
        
        if (second > self.peak2) {
            self.peak2 = second;
            _Freq2Label.text = [NSString stringWithFormat:@"%.2f Hz", second];
        }
    }
    
    // If the frequency lock is OFF
    else if (self.freqLocked == false)
    {
        self.peak1 = first;
        self.peak2 = second;
        
        _Freq1Label.text = [NSString stringWithFormat:@"%.2f Hz", first];
        _Freq2Label.text = [NSString stringWithFormat:@"%.2f Hz", second];
    }

    free(arrayData);
    free(fftMagnitude);
}


@end
