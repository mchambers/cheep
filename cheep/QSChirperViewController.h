//
//  QSChirperViewController.h
//  cheep
//
//  Created by Marc Chambers on 6/28/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <DACircularProgressView.h>
#import "QSSaveChirpViewController.h"

@interface QSChirperViewController : UIViewController
{
    NSTimer* timer;
    NSTimer* progressTimer;
    NSTimeInterval timeRemaining;
    NSDate* recordStartTime;
    NSDate* lastHeartbeatTime;
    CADisplayLink *heartbeat;
    NSTimeInterval maximumDuration;
    BOOL recording;
    BOOL canGoNext;
    AVAudioRecorder* recorder;
    NSURL* audioFileURL;
}

@property (strong, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
- (IBAction)recordButtonDown:(id)sender;
- (IBAction)recordButtonUp:(id)sender;
@property (strong, nonatomic) IBOutlet DACircularProgressView *recordProgress;

@end
