//
//  RYTPopoverDelegate.h
//  RYTSketchView
//
//  Created by Ryan on 20/6/15.
//  Copyright (c) 2015 Ryan. All rights reserved.
//

#ifndef RYTSketchView_RYTPopoverDelegate_h
#define RYTSketchView_RYTPopoverDelegate_h

@protocol RYTPopoverDelegate <NSObject>

- (void)dismissPopoversAnimated:(BOOL)animated;
- (void)popover:(UIPopoverController *)popoverController dismissAnimated:(BOOL)animated;

@end

#endif
