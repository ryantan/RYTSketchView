//
//  PenColorViewController.h
//  RYTSketchView
//
//  Created by Ryan Tan on 3/6/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RYTPopoverDelegate.h"

@class RYTSketchView;

@interface RYTSketchPenOptionsViewController : UIViewController

@property (nonatomic, strong) RYTSketchView *sketchView;
@property (nonatomic, strong) UIPopoverController *popoverController;
//@property (nonatomic, strong) SketchViewController *sketchViewController;
@property (nonatomic, strong) id<RYTPopoverDelegate> popoverDelegate;

- (void)thicknessTapped:(id)sender;
- (void)colorTapped:(id)sender;
- (void)marqueeToolTapped:(id)sender;

- (UIButton*)makeColorButtonWithTag:(NSInteger)tag imageName:(NSString*)imageName;

@end
