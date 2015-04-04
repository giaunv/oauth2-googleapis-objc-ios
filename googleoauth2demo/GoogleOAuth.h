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

@interface GoogleOAuth : UIWebView <UIWebViewDelegate,NSURLConnectionDataDelegate>

@end
