//
//  GoogleOAuth.m
//  googleoauth2demo
//
//  Created by giaunv on 4/4/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import "GoogleOAuth.h"

#define authorizationTokenEndpoint  @"https://accounts.google.com/o/oauth2/auth"
#define accessTokenEndpoint @"https://accounts.google.com/o/oauth2/token"

@interface GoogleOAuth()

// The client ID from the Google Developers Console.
@property (nonatomic, strong) NSString *clientID;
// The client secret value from the Google Developers Console.
@property (nonatomic, strong) NSString *clientSecret;
// The redirect URI after the authorization code gets fetched. For mobile applications it is a standard value.
@property (nonatomic, strong) NSString *redirectUri;
// The authorization code that will exchanged with the access token.
@property (nonatomic, strong) NSString *authorizationCode;
// The refresh token
@property (nonatomic, strong) NSString *refreshToken;
// An array for storing all the scopes we want authorization for.
@property (nonatomic, strong) NSMutableArray *scopes;

// A NSURLConnection object
@property (nonatomic, strong) NSURLConnection *urlConnection;
// The mutable data object that is used for storing incoming data in each connection.
@property (nonatomic, strong) NSMutableData *receivedData;

// The file name of the access token information.
@property (nonatomic, strong) NSString *accessTokenInfoFile;
// The file name of the refresh token
@property (nonatomic, strong) NSString *refreshTokenFile;
// A dictionary for keeping all the access token information together.
@property (nonatomic, strong) NSMutableDictionary *accessTokenInfoDictionary;

// A flag indicating whether an ancess token refresh is on the way or not.
@property (nonatomic) BOOL isRefreshing;

// The parent view where the webview will be shown on.
@property (nonatomic, strong) UIView *parentView;

-(void)showWebviewForUserLogin;
-(void)exchangeAuthorizationCodeForAccessToken;
-(void)refreshAccessToken;

-(NSString *)urlEncodeString:(NSString *)stringToURLEncode;
-(void)storeAccessTokenInfo;
-(void)loadAccessTokenInfo;
-(void)loadRefreshToken;
-(BOOL)checkIfAccessTokenInfoFileExists;
-(BOOL)checkIfRefreshTokenFileExists;
-(BOOL)checkIfShouldRefreshAccessToken;
-(void)makeRequest:(NSMutableURLRequest *)request;
@end

@implementation GoogleOAuth

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // set the access token and the refresh token file paths.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = [paths objectAtIndex:0];
        _accessTokenInfoFile = [[NSString alloc] initWithFormat:@"%@/acctok", docDirectory];
        _refreshTokenFile = [[NSString alloc] initWithFormat:@"%@/reftok", docDirectory];
        
        // set the redirect URI.
        // This is taken from the Google Developer Console.
        _redirectUri = @"urn:ietf:wg:oauth:2.0:oob";
        
        // make any other required initializations
        _receivedData = [[NSMutableData alloc] init];
        _urlConnection = [[NSURLConnection alloc] init];
        _refreshToken = nil;
        _isRefreshing = NO;
    }
    return self;
}

-(void)authorizeUserWithClientID:(NSString *)client_ID andClientSecret:(NSString *)client_Secret andParentView:(UIView *)parent_View andScopes:(NSArray *)scopes{
    // Store into the local private properties all the parameter values.
    _clientID = [[NSString alloc] initWithString:client_ID];
    _clientSecret = [[NSString alloc] initWithString:client_Secret];
    _scopes = [[NSMutableArray alloc] initWithArray:scopes copyItems:YES];
    _parentView = parent_View;
    
    // Check if the access token info file exists or not
    if ([self checkIfAccessTokenInfoFileExists]) {
        // In case it exists, load the access token info and check if the access token is valid
        [self loadAccessTokenInfo];
        if ([self checkIfShouldRefreshAccessToken]) {
            // If the access token is not valid then refresh it
            [self refreshAccessToken];
        } else{
            // Otherwise tell the caller through the delegate class that the authorization is successful
            [self.gOAuthDelegate authorizationWasSuccessful];
        }
    } else{
        // In case of the access token info file is not found then show the webview to let user sign in and allow access to the app.
        [self showWebviewForUserLogin];
    }
}

@end
