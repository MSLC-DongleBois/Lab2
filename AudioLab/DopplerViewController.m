//
//  DopplerViewController.m
//  AudioLab
//
//  Created by Austin Chen on 9/20/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

#import "DopplerViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 8192

@interface DopplerViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;

@end

@implementation DopplerViewController

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
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    __block DopplerViewController * __weak  weakSelf = self;

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

- (void)didReceiveMemoryWarning {
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
    
    
    _micFreqLabel.text = [NSString stringWithFormat:@"%.2f", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    
    free(arrayData);
    free(fftMagnitude);
}

- (IBAction)sliderValueChanged:(id)sender {
    self.freqSliderLabel.text = [NSString stringWithFormat:@"%.0f Hz", self.freqSlider.value * 5000 + 15000];
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
