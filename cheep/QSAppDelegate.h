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

#import <UIKit/UIKit.h>
#import "QSChirpService.h"
#import <AEAudioController.h>
#import <AEAudioFilePlayer.h>
#import <AEBlockFilter.h>

@interface QSAppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDataDelegate>
{
    NSMutableData* _chirpData;
    NSURL* _originalChirpURL;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AEAudioController* audioController;
@property (strong, nonatomic) NSURLConnection* chirpLoader;

-(void)playChirp:(NSURL*)urlToChirp;
-(void)stopChirp;

@end
