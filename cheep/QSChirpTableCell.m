//
//  QSChirpTableCell.m
//  Chirp
//
//  Created by Marc Chambers on 7/6/13.
//  Copyright (c) 2013 Marc Chambers. All rights reserved.
//

#import "QSChirpTableCell.h"

@implementation QSChirpTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.soundWaveController=[[ATWaveFormViewController alloc] init];
        self.soundWaveDisplay=(GLKView*)[self viewWithTag:3];
        self.soundWaveController.view=self.soundWaveDisplay;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chirpPlaybackChanged:) name:@"chirpPlaybackChanged" object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)chirpPlaybackChanged:(NSNotification*)sender
{
    NSURL* newUrl=sender.userInfo[@"chirpUri"];
    if([[newUrl absoluteString] isEqualToString:[self.chirpUri absoluteString]])
    {
        [self setPlaying:YES];
    }
    else
    {
        [self setPlaying:NO];
    }
}

-(BOOL)playing
{
    return _playing;
}

-(void)setPlaying:(BOOL)playing
{
    self.soundWaveDisplay.hidden=!playing;
    _playing=playing;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
