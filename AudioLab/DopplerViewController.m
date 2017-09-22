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
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*4

@interface DopplerViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (nonatomic) float frequency;

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

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:1
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
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
    
    [self.graphHelper setScreenBoundsBottomHalf];
    
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
    
    self.frequency = self.freqSlider.value;

    [self.audioManager play];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [self playAudio];
}

- (void) playAudio {    
    __block DopplerViewController * __weak  weakSelf = self;
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [self.audioManager pause];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream

    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);

    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];

    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];

    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude+(14000*BUFFER_SIZE/44100)
                    withDataLength:BUFFER_SIZE/2*.317
                     forGraphIndex:0
                 withNormalization:300.0
                     withZeroValue:-20];

    [self.graphHelper update]; // update the graph
    
    float maxVal = 0.0;
    vDSP_Length indexLoc = 0;
    vDSP_maxvi(fftMagnitude, 1, &maxVal, &indexLoc, BUFFER_SIZE/2);

    _micFreqLabel.text = [NSString stringWithFormat:@"%.2f Hz", (((float)indexLoc) * self.audioManager.samplingRate/((float)BUFFER_SIZE))];
    
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (IBAction)sliderValueChanged:(id)sender {
    self.freqSliderLabel.text = [NSString stringWithFormat:@"%.0f Hz", self.freqSlider.value];
    
    self.frequency = self.freqSlider.value;
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
