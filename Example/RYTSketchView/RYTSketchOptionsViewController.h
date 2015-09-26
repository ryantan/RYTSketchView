//
//  ClothsetOptionsPopoverController.h
//  RYTSketchView
//
//  Created by Ryan Tan on 15/8/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "RYTPopoverDelegate.h"
////#import "RYTSketchViewControllerDelegate.h"

@class RYTSketchView;

@interface RYTSketchOptionsViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) RYTSketchView *sketchView;
@property (nonatomic, strong) UIPopoverController *popoverController;
//@property (nonatomic, strong) id<RYTPopoverDelegate> popoverDelegate;

//@property (nonatomic, strong) id<RYTSketchViewControllerDelegate> sketchViewControllerDelegate;
//@property (nonatomic, strong) RYTSketchViewController *sketchViewController;

- (void)clearTapped:(id)sender;
//- (void)deleteTapped:(id)sender;
//- (void)duplicateTapped:(id)sender;
- (void)copyTapped:(id)sender;
- (void)pasteTapped:(id)sender;
- (void)cameraTapped:(id)sender;

@end