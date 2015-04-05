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

-(void) showWebviewForUserLogin{
    // Create a string to concatenate all scopes existing in the _scopes array.
    NSString *scope = @"";
    for (int i = 0; i < [_scopes count]; i++) {
        scope = [scope stringByAppendingString:[self urlEncodeString:[_scopes objectAtIndex:i]]];
        
        // If the current scope is other than the last one, then add the "+" sign to the string to separate the scopes.
        if (i < [_scopes count] - 1) {
            scope = [scope stringByAppendingString:@"+"];
        }
    }
    
    // From the URL string.
    NSString *targetURLString = [NSString stringWithFormat:@"%@?scope=%@&amp;redirect_uri=%@&amp;client_id=%@&amp;response_type=code", authorizationTokenEndpoint, scope, _redirectUri, _clientID];
    
    // Do some basic webview setup.
    [self setDelegate:self];
    [self setScalesPageToFit:YES];
    [self setAutoresizingMask:_parentView.autoresizingMask];
    
    // Make the request and add itself (webview) to the parent view.
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:targetURLString]]];
    [_parentView addSubview:self];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    // Get the webpage title.
    NSString *webviewTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    // NSLog(@"Webview Title = %@", webviewTitle)
    
    // Check for the "Success token" literal in the title.
    if ([webviewTitle rangeOfString:@"Success code"].location != NSNotFound) {
        // The oauth code has been retrieved.
        // Break the title based on the equal sign (=).
        NSArray *titleParts = [webviewTitle componentsSeparatedByString:@"="];
        // The second part is the oauth token
        _authorizationCode = [[NSString alloc] initWithString:[titleParts objectAtIndex:1]];
        
        // Show a "Please wait..." message to the webview.
        NSString *html = @"<html><head><title>Please wait</title></head><body><h1>Please wait...</h1></body></html>";
        [self loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        
        // Exchange the authorization code for an access code
        [self exchangeAuthorizationCodeForAccessToken];
    } else {
        if ([webviewTitle rangeOfString:@"access_denied"].location != NSNotFound) {
            // In case that the user tapped on the Cancel button instead of the Accept, then just remove the webview from the superview.
            [webView removeFromSuperview];
        }
    }
}

-(void)exchangeAuthorizationCodeForAccessToken{
    // Create a string containing all the post parameters required to exchange the authorization code with the access token.
    NSString *postParams = [NSString stringWithFormat:@"code=%@&amp;client_id=%@&amp;client_secret=%@&amp;redirect_uri=%@&amp;grant_type=authorization_code", _authorizationCode, _clientID, _clientSecret, _redirectUri];
    
    // Create a mutable request object and set its properties.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:accessTokenEndpoint]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postParams dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Make the request.
    [self makeRequest:request];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.gOAuthDelegate errorOccuredWithShortDescription:@"Connection failed" andErrorDetails:[error localizedDescription]];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // This object will be used to store the converted received JSON data to string.
    NSString *responseJSON;
    
    // This flag indicates whether the response was received after an API call and out of the following cases.
    BOOL isAPIResponse = YES;
    
    // Convert the received data in NSString format.
    responseJSON = [[NSString alloc] initWithData:(NSData *)_receivedData encoding:NSUTF8StringEncoding];
    
    // Check for invalid refresh token.
    // In that case guide the user to enter the credentials again.
    if ([responseJSON rangeOfString:@"invalid_grant"].location != NSNotFound) {
        if (_isRefreshing) {
            _isRefreshing = NO;
        }
        
        [self showWebviewForUserLogin];
        
        isAPIResponse = NO;
    }
    
    // Check for access token.
    if ([responseJSON rangeOfString:@"access_token"].location != NSNotFound) {
        // This is the case where the access token has been fetched.
        [self storeAccessTokenInfo];
        
        // Remove the webview from the superview.
        [self removeFromSuperview];
        
        if (_isRefreshing) {
            _isRefreshing = NO;
        }
        
        // Notify the caller class that the authorization was successful.
        [self.gOAuthDelegate authorizationWasSuccessful];
        
        isAPIResponse = NO;
    }
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    // Append any new data to the _receivedData object.
    [_receivedData appendData:data];
}

-(void) refreshAccessToken{
    // Load the refresh token if it's not loaded already.
    if (_refreshToken == nil) {
        [self loadRefreshToken];
    }
    
    // Set the HTTP POST parameters required for refreshing the access token.
    NSString *refreshPostParams = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&client_secret=%@&grant_type=refresh_token", _refreshToken, _clientID, _clientSecret];
    
    // Indicate that an access token refresh process is on the way.
    _isRefreshing = YES;
    
    // Create the request object and set its properties.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:accessTokenEndpoint]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[refreshPostParams dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Make the request.
    [self makeRequest:request];
}

@end
