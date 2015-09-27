//
//  NSObject+UIPopover_Iphone.m
//  RYTSketchView
//
//  Created by Ryan on 27/9/15.
//  Copyright (c) 2015 Ryan. All rights reserved.
//

#import "NSObject+UIPopover_Iphone.h"

@implementation UIPopoverController (overrides)

+(BOOL)_popoversDisabled {
    return NO;
}

@end