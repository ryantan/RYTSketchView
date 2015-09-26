//
//  RYTJoystickViewControllerDelegate.h
//  RYTSketchView
//
//  Created by Ryan Tan on 23/5/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RYTJoystickView;

@protocol RYTJoystickViewDelegate <NSObject>

- (void)joystick:(RYTJoystickView*)joystick moved:(CGPoint)delta;

@end
