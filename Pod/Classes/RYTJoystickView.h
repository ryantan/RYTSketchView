//
//  JoystickView.h
//  RYTSketchView
//
//  Created by Ryan Tan on 23/5/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RYTJoystickViewDelegate.h"

@interface RYTJoystickView : UIView {
    
    CGPoint firstLocation;
    UIView *stick;
    BOOL shouldShowJoystick;
}

@property (nonatomic, strong) id<RYTJoystickViewDelegate> delegate;
@property (nonatomic, assign) BOOL shouldShowJoystick;

- (void)resetJoystick;

@end
