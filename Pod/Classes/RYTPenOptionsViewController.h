//
//  PenColorViewController.h
//  RYTSketchView
//
//  Created by Ryan Tan on 3/6/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RYTSketchView;
@class SketchViewController;

@interface RYTPenOptionsViewController : UIViewController {
    UIButton *btnThick1;
    UIButton *btnThick2;
    UIButton *btnThick3;
    
    UIButton *btnColor1;
    UIButton *btnColor2;
    UIButton *btnColor3;
    UIButton *btnColor4;
    UIButton *btnColor5;
    UIButton *btnColor6;
    
    UIButton *btnMarqueeTool;
    
}

@property (nonatomic, strong) RYTSketchView *sketchView;
@property (nonatomic, strong) SketchViewController *sketchViewController;

- (void)thicknessTapped:(id)sender;
- (void)colorTapped:(id)sender;
- (void)marqueeToolTapped:(id)sender;

- (UIButton*)makeColorButtonWithTag:(NSInteger)tag imageName:(NSString*)imageName;

@end
