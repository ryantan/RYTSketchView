//
//  RYTViewController.h
//  RYTSketchView
//
//  Created by Ryan on 06/20/2015.
//  Copyright (c) 2014 Ryan. All rights reserved.
//

@import UIKit;

#import <RYTSketchView/RYTSketchView.h>
#import "RYTPopoverDelegate.h"

@interface RYTViewController : UIViewController <RYTPopoverDelegate, RYTSketchViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *sketchViewWrapper;

- (IBAction)penOptionsTapped:(id)sender;
- (IBAction)penRedTapped:(id)sender;
- (IBAction)eraserTapped:(id)sender;
- (IBAction)sketchActionsTapped:(id)sender;
- (IBAction)undoTapped:(id)sender;
- (IBAction)redoTapped:(id)sender;
- (IBAction)zoomValueChanged:(id)sender;

@end
