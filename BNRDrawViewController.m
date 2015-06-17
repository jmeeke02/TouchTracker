//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by Jordan Meeker on 5/5/15.
//  Copyright (c) 2015 Jordan Meeker. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@implementation BNRDrawViewController

- (void) loadView {
   
   self.view =[[BNRDrawView alloc] initWithFrame:CGRectZero];
}


@end
