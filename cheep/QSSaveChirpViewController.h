//
//  QSSaveChirpViewController.h
//  cheep
//
//  Created by Marc Chambers on 6/29/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AEAudioController.h>
#import <AEAudioFilePlayer.h>
#import <AEBlockFilter.h>
#import "ATWaveFormViewController.h"
#import <AEFloatConverter.h>
#import "SSTextView.h"
#import "QSChirpService.h"
#import <DACircularProgressView.h>

@interface QSSaveChirpViewController : UIViewController <NSURLConnectionDataDelegate>
{
    AEAudioController* _audioController;
    AEFloatConverter* _converter;
    AudioBufferList* _processBuffer;
}
@property (strong, nonatomic) IBOutlet UILabel *chirpingLabel;
@property (strong, nonatomic) IBOutlet DACircularProgressView *chirpingProgress;

@property (nonatomic, strong) NSURL* audioFileURL;
@property (nonatomic, strong) ATWaveFormViewController* waveFormController;
@property (strong, nonatomic) IBOutlet SSTextView *chirpCaption;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;

- (IBAction)doneButtonTapped:(id)sender;
@end
