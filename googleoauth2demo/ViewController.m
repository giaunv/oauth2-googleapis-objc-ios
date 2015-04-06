//
//  ViewController.m
//  googleoauth2demo
//
//  Created by giaunv on 4/4/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import "ViewController.h"
#import "GoogleOAuth.h"

#define CLIENT_ID  @"157740772866viioslkeann2edsg7bsdhml2gl285jd0.apps.googleusercontent.com"
#define CLIENT_SECRECT  @"wEiNgY9YBOtszDBM6lZ9BZxj"
#define SCOPE_URL @"https://www.googleapis.com/auth/userinfo.profile"
#define API_URL @"https://www.googleapis.com/oauth2/v1/userinfo"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *arrProfileInfo;
@property (nonatomic, strong) NSMutableArray *arrProfileInfoLabel;
@property (nonatomic, strong) GoogleOAuth *googleOAuth;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_table setDelegate:self];
    [_table setDataSource:self];
    
    _arrProfileInfo = [[NSMutableArray alloc] init];
    _arrProfileInfoLabel = [[NSMutableArray alloc] init];
    
    _googleOAuth = [[GoogleOAuth alloc] initWithFrame:self.view.frame];
    [_googleOAuth setGOAuthDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showProfile:(id)sender {
    [_googleOAuth authorizeUserWithClientID:CLIENT_ID andClientSecret:CLIENT_SECRECT andParentView:self.view andScopes:[NSArray arrayWithObjects:SCOPE_URL, nil]];
}

- (IBAction)revokeAccess:(id)sender {
    [_googleOAuth revokeAccessToken];
}

- (void) authorizationWasSuccessful{
    [_googleOAuth callAPI:API_URL withHttpMethod:httpMethod_GET postParameterNames:nil postParameterValues:nil];
}

- (void)accessTokenWasRevoked{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Your access was revoked" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    
    [_arrProfileInfo removeAllObjects];
    [_arrProfileInfoLabel removeAllObjects];
    
    [_table reloadData];
}

-(void)errorInResponseWithBody:(NSString *)errorMessage:(NSString *)errorShortDescription andErrorDetails:(NSString *)errorDetails{
    NSLog(@"%@", errorShortDescription);
    NSLog(@"%@", errorDetails);
}


-(void)errorInResponseWithBody:(NSString *)errorMessage{
    NSLog(@"%@", errorMessage);
}

-(void)responseFromServiceWasReceived:(NSString *)responseJSONAsString andResponseJSONAsData:(NSData *)responseJSONAsData{
    if ([responseJSONAsString rangeOfString:@"family_name"].location != NSNotFound) {
        NSError *error;
        NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseJSONAsData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
        if (error) {
            NSLog(@"An error occured while converting JSON data to dictionary.");
            return;
        }
        else{
            if (_arrProfileInfoLabel != nil) {
                _arrProfileInfoLabel = nil;
                _arrProfileInfo = nil;
                _arrProfileInfo = [[NSMutableArray alloc] init];
            }
            
            _arrProfileInfoLabel = [[NSMutableArray alloc] initWithArray:[dictionary allKeys] copyItems:YES];
            for (int i=0; i<[_arrProfileInfoLabel count]; i++) {
                [_arrProfileInfo addObject:[dictionary objectForKey:[_arrProfileInfoLabel objectAtIndex:i]]];
            }
            
            [_table reloadData];
        }
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [_arrProfileInfo count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIndentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIndentifier];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        
        [[cell textLabel] setFont:[UIFont fontWithName:@"Trebuchet MS" size:15.0]];
        [[cell textLabel] setShadowOffset:CGSizeMake(1.0, 1.0)];
        [[cell textLabel] setShadowColor:[UIColor whiteColor]];
        
        [[cell detailTextLabel] setFont:[UIFont fontWithName:@"Trebuchet MS" size:13.0]];
        [[cell detailTextLabel] setTextColor:[UIColor grayColor]];
    }
    
    [[cell textLabel] setText:[_arrProfileInfo objectAtIndex:[indexPath row]]];
    [[cell detailTextLabel] setText:[_arrProfileInfoLabel objectAtIndex:[indexPath row]]];
    
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}
@end
