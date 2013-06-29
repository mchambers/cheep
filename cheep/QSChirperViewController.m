//
//  QSChirperViewController.m
//  cheep
//
//  Created by Marc Chambers on 6/28/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import "QSChirperViewController.h"

@interface QSChirperViewController ()

@end

@implementation QSChirperViewController

-(NSURL*)generateTemporaryFileLocation
{
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:@"aac"];
    return fileURL;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    maximumDuration=6.0000; // THE ENTIRE APP IS BASED ON THIS LINE OF CODE
    timeRemaining=maximumDuration;
    
    [self.recordProgress setTrackTintColor:[UIColor lightGrayColor]];
    [self.recordProgress setProgressTintColor:[UIColor blueColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRecordButton:nil];
    [self setTimeRemainingLabel:nil];
    [self setRecordProgress:nil];
    [super viewDidUnload];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // rawr
    if([segue.destinationViewController respondsToSelector:@selector(setAudioFileURL:)])
        [segue.destinationViewController setAudioFileURL:audioFileURL];
}

-(void)allowGoNext
{
    canGoNext=YES;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

-(void)updateProgress:(id)sender
{
    NSTimeInterval elapsedTime=[lastHeartbeatTime timeIntervalSinceNow];
    timeRemaining+=elapsedTime;
    lastHeartbeatTime=[NSDate date];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.recordProgress.progress=(maximumDuration-timeRemaining) / maximumDuration;
    });
    
    self.timeRemainingLabel.text=[NSString stringWithFormat:@"%.1fs", timeRemaining];
    
    if(timeRemaining<=4 && !canGoNext)
    {
        [self allowGoNext];
    }
    
    if(timeRemaining<=0)
    {
        // timer has expired!
        NSLog(@"We're out of time, bro");
        [self.recordButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)prepareToRecord
{
    NSError* error;
    
    if(recorder)
    {
        [recorder stop];
        recorder=nil;
    }
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSDictionary* recordSettings=@{AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                   AVSampleRateKey:@(44100.0),
                                   AVNumberOfChannelsKey:@(2),
                                   AVEncoderBitRateKey:@(128000),
                                   AVLinearPCMBitDepthKey:@(16),
                                   AVEncoderAudioQualityKey:@(AVAudioQualityHigh)
                                   };
    
    audioFileURL=[self generateTemporaryFileLocation];
    
    recorder=[[AVAudioRecorder alloc] initWithURL:audioFileURL settings:recordSettings error:&error];
    NSLog(@"Recorder initialized, error if any: %@", error);
    BOOL ret=[recorder prepareToRecord];
    if(!ret)
    {
        NSLog(@"Failed to prepare to record");
    }
}

- (IBAction)recordButtonDown:(id)sender {
    if(timeRemaining<=0) return;
    
    if(heartbeat)
    {
        [heartbeat invalidate];
        heartbeat=nil;
    }
            
    if(!recorder)
        [self prepareToRecord];
    
    recordStartTime=[NSDate date];
    lastHeartbeatTime=[NSDate date];
    
    heartbeat = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    heartbeat.frameInterval = 1;
    [heartbeat addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [recorder record];
    NSLog(@"Recording started with %f remaining", timeRemaining);
    
    recording=YES;
}

- (IBAction)recordButtonUp:(id)sender {
    if(!recording) return;
    
    NSLog(@"Recording stopped");
    
    recording=NO;
    [heartbeat invalidate];
    heartbeat=nil;
    
    [recorder pause];
    
    if(timeRemaining<=0)
    {
       [self.recordButton setEnabled:NO];
        self.timeRemainingLabel.text=@"0.0s";
        
        [recorder stop];
        recorder=nil;
        
        long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[audioFileURL absoluteString] error:nil][NSFileSize] longLongValue];
        NSLog(@"File should be available at %@, size is %lld", audioFileURL, fileSize);
    }
}
@end
