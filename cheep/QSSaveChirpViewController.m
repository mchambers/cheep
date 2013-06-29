//
//  QSSaveChirpViewController.m
//  cheep
//
//  Created by Marc Chambers on 6/29/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import "QSSaveChirpViewController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.chirpCaption.placeholder=@"Type a caption for your chirp.";
    
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
    
    [self.chirpCaption becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setChirpCaption:nil];
    [super viewDidUnload];
}
@end
