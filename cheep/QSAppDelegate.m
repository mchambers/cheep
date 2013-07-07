// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "QSAppDelegate.h"
#import "ATWaveFormViewController.h"

@implementation QSAppDelegate

-(void)stopChirp
{
    if(!self.audioController)
        return;
    
    [self.audioController removeChannels:self.audioController.channels];
    [self.audioController stop];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_chirpData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.aac", [[NSProcessInfo processInfo] globallyUniqueString]]];
    
    [_chirpData writeToFile:path atomically:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSLog(@"Finished loading chirp, spool to play from temp location: %@", path);
        [self playChirp:[NSURL fileURLWithPath:path]];
    });
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Begin receiving chirp data");
    
    if(!_chirpData)
        _chirpData=[[NSMutableData alloc] init];
    [_chirpData setLength:0];
}

-(void)playChirp:(NSURL*)urlToChirp
{
    if(!self.audioController)
    {
        self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
    }
    
    if(![urlToChirp isFileURL])
    {
        NSLog(@"Need to load this chirp from the net");
        
        // spool up the downloader and get this shit goin'
        NSURLRequest* chirpLoadRequest=[NSURLRequest requestWithURL:urlToChirp];
        if(self.chirpLoader)
        {
            [self.chirpLoader cancel];
            _chirpData=nil;
            self.chirpLoader=nil;
        }
        
        self.chirpLoader=[[NSURLConnection alloc] initWithRequest:chirpLoadRequest delegate:self startImmediately:NO];
        [self.chirpLoader scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.chirpLoader start];
        
        return;
    }
    
    NSLog(@"Playing chirp from disk");
    
    AEAudioFilePlayer* chirp = [AEAudioFilePlayer audioFilePlayerWithURL:urlToChirp audioController:self.audioController error:NULL];
    
    chirp.loop = YES;
    
    if(self.audioController.channels || self.audioController.channels.count>0)
        [self.audioController removeChannels:self.audioController.channels];
    
    [self.audioController addChannels:@[chirp]];
    
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"chirpPlaybackChanged" object:nil userInfo:@{@"chirpUri":urlToChirp}];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:161.0/255.0 green:0.0/255.0 blue:64.0/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f], UITextAttributeTextShadowColor:[UIColor clearColor]}];
    
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"blank"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f], UITextAttributeTextShadowColor:[UIColor clearColor]} forState:UIControlStateNormal];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navheader"] forBarMetrics:UIBarMetricsDefault];

    NSString* authToken;
    NSString* curUser;
    
    //authToken=[[NSUserDefaults standardUserDefaults] stringForKey:@"mobileServiceAuthenticationToken"];
    //curUser=[[NSUserDefaults standardUserDefaults] stringForKey:@"mobileServiceUserId"];
    
    if(curUser!=nil && authToken!=nil)
    {
        MSUser* user=[[MSUser alloc] initWithUserId:curUser];
        user.mobileServiceAuthenticationToken=authToken;
        [[QSChirpService defaultService] setCurrentUser:user];
    }
    
    if([[QSChirpService defaultService] currentUser]!=nil)
    {
        
    }
    else
    {
        self.window.rootViewController=[self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"WelcomeView"];
    }
    
    return YES;
}

@end
