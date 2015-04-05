//
//  GoogleOAuth.h
//  googleoauth2demo
//
//  Created by giaunv on 4/4/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    httpMethod_GET,
    httpMethod_POST,
    httpMethod_DELETE,
    httpMethod_PUT
} HTTP_Method;

@protocol GoogleOAuthDelegate
-(void)authorizationWasSuccessful;
-(void)accessTokenWasRevoked;
-(void)responseFromServiceWasReceived:(NSString *)responseJSONAsString andResponseJSONAsData:(NSData *)responseJSONAsData;
-(void)errorOccuredWithShortDescription:(NSString *)errorShortDescription andErrorDetails:(NSString *)errorDetails;
-(void)errorInResponseWithBody:(NSString *)errorMessage;
@end

@interface GoogleOAuth : UIWebView <UIWebViewDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) id<GoogleOAuthDelegate> gOAuthDelegate;
-(void) authorizeUserWithClientID:(NSString *)client_ID andClientSecret:(NSString *)client_Secret andParentView:(UIView *)parent_View andScopes:(NSArray *)scopes;
@end