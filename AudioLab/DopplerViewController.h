//
//  DopplerViewController.h
//  AudioLab
//
//  Created by Austin Chen on 9/20/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DopplerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *freqSlider;
@property (weak, nonatomic) IBOutlet UILabel *freqSliderLabel;

@property (weak, nonatomic) IBOutlet UILabel *micFreqLabel;

@end
