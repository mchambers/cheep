//
//  QSWelcomeViewController.m
//  cheep
//
//  Created by Marc Chambers on 6/28/13.
//  Copyright (c) 2013 MobileServices. All rights reserved.
//

#import "QSWelcomeViewController.h"

@interface QSWelcomeViewController ()

@end

@implementation QSWelcomeViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)connectWithIdentityProvider:(NSString*)provider
{
    MSClient* client=[[QSTodoService defaultService] client];
    
    [client loginWithProvider:provider controller:self animated:YES completion:^(MSUser *user, NSError *error) {
        if(user!=nil && error==nil)
        {
            [[QSTodoService defaultService] setCurrentUser:user];
            
            NSLog(@"User logged in: id %@, token %@", user.userId, user.mobileServiceAuthenticationToken);
            [[NSUserDefaults standardUserDefaults] setValue:user.mobileServiceAuthenticationToken forKey:@"mobileServiceAuthenticationToken"];
            [[NSUserDefaults standardUserDefaults] setValue:user.userId forKey:@"mobileServiceUserId"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self performSegueWithIdentifier:@"Login" sender:self];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }];
}

- (IBAction)connectWithFacebook:(id)sender {
    [self connectWithIdentityProvider:@"facebook"];
}

- (IBAction)connectWithTwitter:(id)sender {
    [self connectWithIdentityProvider:@"twitter"];
}
@end
