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

#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>
#import "QSChirpListViewController.h"
#import "QSChirpService.h"
#import "UIImage+GaussianBlur.h"
#import "QSChirpTableCell.h"
#import "QSAppDelegate.h"

#pragma mark * Private Interface

@interface QSChirpListViewController ()

// Private properties
@property (strong, nonatomic)   QSChirpService   *todoService;
@property (nonatomic)           BOOL            useRefreshControl;

@end

#pragma mark * Implementation

@implementation QSChirpListViewController

@synthesize todoService;
@synthesize itemText;
@synthesize activityIndicator;

#pragma mark * UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create the todoService - this creates the Mobile Service client inside the wrapped service
    self.todoService = [QSChirpService defaultService];
    
    // Set the busy method
    UIActivityIndicatorView *indicator = self.activityIndicator;
    self.todoService.busyUpdate = ^(BOOL busy)
    {
        if (busy)
        {
            [indicator startAnimating];
        } else
        {
            [indicator stopAnimating];
        }
    };
    
    // add the refresh control to the table (iOS6+ only)
    [self addRefreshControl];
    
    // load the data
    [self refresh];
    
    RESideMenuItem* homeItem=[[RESideMenuItem alloc] initWithTitle:@"Home" image:nil highlightedImage:nil action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
    }];
    
    RESideMenuItem* explore=[[RESideMenuItem alloc] initWithTitle:@"Explore" image:nil highlightedImage:nil action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
    }];
    
    RESideMenuItem* profile=[[RESideMenuItem alloc] initWithTitle:@"Profile" image:nil highlightedImage:nil action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
    }];
    
    RESideMenuItem* findFriendsItem=[[RESideMenuItem alloc] initWithTitle:@"Find Friends" image:nil highlightedImage:nil action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
    }];
    
    RESideMenuItem* logout=[[RESideMenuItem alloc] initWithTitle:@"Log Out" image:nil highlightedImage:nil action:^(RESideMenu *menu, RESideMenuItem *item) {
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:^(void){
            [[QSChirpService defaultService] setCurrentUser:nil];
            [menu hide];
        }];
    }];
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 640.0f, 960.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor scrollViewTexturedBackgroundColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    sideMenu=[[RESideMenu alloc] initWithItems:@[homeItem, explore, profile, findFriendsItem, logout]];
    sideMenu.hideStatusBarArea=NO;
    [sideMenu setBackgroundImage:image];
}

-(void)refresh
{
    // only activate the refresh control if the feature is available
    if (self.useRefreshControl == YES) {
        [self.refreshControl beginRefreshing];
    }
    
    [[self.todoService client] invokeAPI:@"feed" data:nil HTTPMethod:@"GET" parameters:nil headers:nil completion:^(NSData *result, NSHTTPURLResponse *response, NSError *error) {
        if(self.useRefreshControl==YES)
            [self.refreshControl endRefreshing];
        
        NSLog(@"%i", response.statusCode);
        
        if(response.statusCode==200)
        {
            NSDictionary* deserializedResponse=[NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
            NSLog(@"%@", deserializedResponse);
            
            self.todoService.items=deserializedResponse[@"items"];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark * UITableView methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 159.0f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* item=[self.todoService.items objectAtIndex:indexPath.row];
    
    QSAppDelegate* delegate=(QSAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSURL* chirpURL=[NSURL URLWithString:item[@"chirpUri"]];
    [delegate playChirp:chirpURL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChirpCell";
    QSChirpTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[QSChirpTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Set the label on the cell and make sure the label color is black (in case this cell
    // has been reused and was previously greyed out
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    UILabel* ownerName=(UILabel*)[cell viewWithTag:2];
    
    label.textColor = [UIColor blackColor];
    NSDictionary *item = [self.todoService.items objectAtIndex:indexPath.row];
    label.text = item[@"caption"];
    ownerName.text = item[@"name"];
    
    [cell setPlaying:NO];
    cell.chirpUri=[NSURL URLWithString:item[@"chirpUri"]];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Always a single section
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of items in the todoService items array
    return [self.todoService.items count];
}

#pragma mark * UITextFieldDelegate methods


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark * UI Actions

- (IBAction)leftMenuButtonTap:(id)sender {
    [sideMenu show];
}

#pragma mark * iOS Specific Code

// This method will add the UIRefreshControl to the table view if
// it is available, ie, we are running on iOS 6+

- (void)addRefreshControl
{
    Class refreshControlClass = NSClassFromString(@"UIRefreshControl");
    if (refreshControlClass != nil)
    {
        // the refresh control is available, let's add it
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self
                                action:@selector(onRefresh:)
                      forControlEvents:UIControlEventValueChanged];
        self.useRefreshControl = YES;
    }
}

- (void)onRefresh:(id) sender
{
    [self refresh];
}


@end
