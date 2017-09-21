//
//  DopplerViewController.h
//  AudioLab
//
//  Created by Austin Chen on 9/19/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DopplerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISlider *dopplerFreqSlider;
@property (weak, nonatomic) IBOutlet UILabel *dopperFreqSliderLabel;

@end
