//
//  QSChirpTableCell.h
//  Chirp
//
//  Created by Marc Chambers on 7/6/13.
//  Copyright (c) 2013 Marc Chambers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "ATWaveFormViewController.h"

@interface QSChirpTableCell : UITableViewCell
{
    BOOL _playing;
}

@property (nonatomic, strong) GLKView* soundWaveDisplay;
@property (nonatomic, strong) ATWaveFormViewController* soundWaveController;
@property (nonatomic, strong) NSURL* chirpUri;

@property (nonatomic, assign) BOOL playing;

@end
