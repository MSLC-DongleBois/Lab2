//
//  BrightnessViewController.m
//  AudioLab
//
//  Created by Austin Chen on 9/22/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

#import "BrightnessViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*4

@interface BrightnessViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (nonatomic) float frequency;
@end

@implementation BrightnessViewController

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


- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
    
    __block BrightnessViewController * __weak  weakSelf = self;
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
    
    self.frequency = 20000;
    
    [[UIScreen mainScreen] setBrightness:0];
    
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(continuousFFT:)
                                   userInfo:nil
                                    repeats:YES];
    
    [self.audioManager play];
}

-(void) continuousFFT: (NSTimer*) t
{
    [self getNewFFT];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [self playAudio];
}



- (void) playAudio {
    __block BrightnessViewController * __weak  weakSelf = self;
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         __block float phase = 0.0;
         __block float samplingRate = weakSelf.audioManager.samplingRate;
         [weakSelf.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
          {
              double phaseIncrement = 2*M_PI*self.frequency/samplingRate;
              double sineWaveRepeatMax = 2*M_PI;
              for (int i=0; i < numFrames; ++i)
              {
                  data[i] = sin(phase);
                  phase += phaseIncrement;
                  if (phase >= sineWaveRepeatMax) phase -= sineWaveRepeatMax;
              }
          }];
     }];
}

- (void) getNewFFT{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    float playedFreqBin = self.frequency / (self.audioManager.samplingRate/(BUFFER_SIZE));
    int playedFreqIndex = round(playedFreqBin);

    float leftMagnitude = 0.0;
    float rightMagnitude = 0.0;
    
    // We are searching for the cumulative magnitudes to the left of the frequency. First, we must aggregate every frequency 8 buckets to
    // the LEFT of the index that is currently playing
    for (int i = playedFreqIndex - 8; i < playedFreqIndex; i++)
    {
        leftMagnitude += fftMagnitude[i];
    }
    
    // Then, we must aggregate every bucket to the RIGHT of the index that is currently playing
    for (int i = playedFreqIndex + 1; i < playedFreqIndex + 9; i++) {
        rightMagnitude += fftMagnitude[i];
    }
    
    // If the difference between the two magnitudes is less than 50, we are going to ignore the motion.
    // We ignore it because there is no meaningful difference between the two.
    if(fabs(leftMagnitude - rightMagnitude) < 60)
    {
        [[UIScreen mainScreen] setBrightness:0.4];
        self.peekabooLabel.text = @"";
        self.emojiLabel.text = @"🙈";
    }
    
    // Motion away
    else if (leftMagnitude > rightMagnitude)
    {
        [[UIScreen mainScreen] setBrightness:0.4];
        self.peekabooLabel.text = @"";

        self.emojiLabel.text = @"🙈";
    }
    
    // Motion towards
    else if (leftMagnitude < rightMagnitude)
    {
        [[UIScreen mainScreen] setBrightness:1];
        self.emojiLabel.text = @"🐵";
        self.peekabooLabel.text = @"Peekaboo!";

    }
    
    // Free up the data
    free(arrayData);
    free(fftMagnitude);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [[UIScreen mainScreen] setBrightness:0.7];
    [self.audioManager pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
