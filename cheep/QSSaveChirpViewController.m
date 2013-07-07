//
//  QSSaveChirpViewController.m
//  cheep
//
//  Created by Marc Chambers on 6/29/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import "QSSaveChirpViewController.h"
#import <YRDropdownView.h>
#import "QSAppDelegate.h"

@interface QSSaveChirpViewController ()

@end

@implementation QSSaveChirpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [(QSAppDelegate*)([[UIApplication sharedApplication] delegate]) stopChirp];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.chirpCaption.placeholder=@"Type a caption for your chirp. Include #hashtags so people can discover your chirp.";
    
    [(QSAppDelegate*)([[UIApplication sharedApplication] delegate]) playChirp:self.audioFileURL];
    
    /*
    _audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
    
    AEAudioFilePlayer* chirp = [AEAudioFilePlayer audioFilePlayerWithURL:self.audioFileURL audioController:_audioController error:NULL];
    
    chirp.loop = YES;
    
    [_audioController addChannels:@[chirp]];
    
    AEBlockFilter *filter = [AEBlockFilter filterWithBlock:
                             ^(AEAudioControllerFilterProducer producer,
                               void                     *producerToken,
                               const AudioTimeStamp     *time,
                               UInt32                    frames,
                               AudioBufferList          *audio) {
                                 
                                 OSStatus status = producer(producerToken, audio, &frames);
                                 if ( status != noErr ) return;
                                 
                                 Float32 *data = audio->mBuffers[0].mData;
                                 int i;
                                 updateDrawBufferSizes();
                                 for (i=0; i<frames; i++)
                                 {
                                     if ((i+drawBufferIdx) >= drawBufferLen)
                                     {
                                         cycleOscilloscopeLines();
                                         drawBufferIdx = -i;
                                     }
                                     drawBuffers[0][i + drawBufferIdx] = data[0];
                                     data += 1;
                                 }
                                 drawBufferIdx += frames;
                             }];
    
    [_audioController addFilter:filter toChannel:chirp];
    
    [_audioController start:NULL];
    */
    
    
    [self.chirpCaption becomeFirstResponder];
    
    [self.chirpingProgress setTrackTintColor:[UIColor colorWithRed:91.0f/255.0f green:86.0f/255.0f blue:87.0f/255.0f alpha:1.0f]];
    [self.chirpingProgress setProgressTintColor:[UIColor colorWithRed:219.0f/255.0f green:121.0f/255.0f blue:114.0f/255.0f alpha:1.0f]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setChirpCaption:nil];
    [self setChirpingLabel:nil];
    [self setChirpingProgress:nil];
    [self setDoneButton:nil];
    [super viewDidUnload];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"Upload finished, status code %i", response.statusCode);
    if(response.statusCode==201)
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        [YRDropdownView showDropdownInView:self.view title:@"Couldn't chirp." detail:@"We weren't able to chirp. This might mean your internet isn't working. You can try again."];
        
        self.doneButton.enabled=YES;
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.chirpingProgress.progress=(totalBytesWritten / totalBytesExpectedToWrite);
        self.chirpingLabel.text=[NSString stringWithFormat:@"%.0f%%", self.chirpingProgress.progress*100];
    });
}

-(void)showProgressStuff
{
    self.chirpingLabel.hidden=NO;
    self.chirpingProgress.hidden=NO;
    self.chirpCaption.hidden=YES;
    [self.view endEditing:YES];
    
    [self.doneButton setEnabled:NO];
}

-(void)hideProgressStuff
{
    self.chirpingLabel.hidden=YES;
    self.chirpingProgress.hidden=YES;
    self.chirpCaption.hidden=NO;
    
    [self.doneButton setEnabled:YES];
}

- (IBAction)doneButtonTapped:(id)sender {
    MSClient* client=[[QSChirpService defaultService] client];
    MSTable* chirpTable=[client tableWithName:@"Chirp"];
    
    [_audioController setMuteOutput:YES];
    
    NSDictionary* chirp=@{
                         @"resourceName":[self.audioFileURL lastPathComponent],
                         @"caption":self.chirpCaption.text,
                         @"created":[NSDate date]
                         };
    
    [self showProgressStuff];
    
    [chirpTable insert:chirp completion:^(NSDictionary *item, NSError *error) {
        if(error)
        {
            [YRDropdownView showDropdownInView:self.view title:@"Couldn't chirp." detail:@"We weren't able to chirp. This might mean your internet isn't working. You can try again."];
            
            [self hideProgressStuff];
        }
        else
        {
            NSString* sasQueryString=[item objectForKey:@"sasQueryString"];
            NSString* resourceUri=[item objectForKey:@"chirpUri"];
            NSURL* audioFileUrl=[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", resourceUri, sasQueryString]];
            
            // upload the audio file
            NSData *audioData = [NSData dataWithContentsOfURL:self.audioFileURL];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:audioFileUrl];
            [request setHTTPMethod:@"PUT"];
            [request addValue:@"audio/aac" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:audioData];
            
            NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            [conn start];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
            });
        }
    }];
}
@end
