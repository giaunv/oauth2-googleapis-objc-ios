//
//  ViewController.h
//  googleoauth2demo
//
//  Created by giaunv on 4/4/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *table;

- (IBAction)showProfile:(id)sender;


- (IBAction)revokeAccess:(id)sender;

@end

