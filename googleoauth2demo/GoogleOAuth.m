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

@end
