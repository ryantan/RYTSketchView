//
//  JoystickView.m
//  RYTSketchView
//
//  Created by Ryan Tan on 23/5/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import "RYTJoystickView.h"

@implementation RYTJoystickView

@synthesize delegate, shouldShowJoystick;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        

        //self.backgroundColor = [UIColor redColor]; // For testing
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Joystick-bg"]];
        
        stick = [[UIView alloc]init];
        stick.frame = CGRectMake(50, 50, 50, 50);
        
        //stick.backgroundColor = [UIColor blueColor]; // For testing
        stick.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Joystick-stick"]];
        
        [self addSubview:stick];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //NSLog(@"JoystickViewController.touchesBegan:withEvent:");
    UITouch *theTouch = (UITouch*)[[touches allObjects] objectAtIndex:0];
    
    firstLocation = [theTouch locationInView:self];
    //NSLog(@"firstLocation=%@", NSStringFromCGPoint(firstLocation));
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    //NSLog(@"JoystickViewController.touchesMoved:withEvent:");
    UITouch *theTouch = (UITouch*)[[touches allObjects] objectAtIndex:0];
    
    CGPoint currLocation = [theTouch locationInView:self];
    //NSLog(@"currLocation=%@", NSStringFromCGPoint(currLocation));
    //[theTouch locationInView:self.view];
    
    
    CGPoint delta;
    //delta = CGPointMake((currLocation.x - firstLocation.x)/self.bounds.size.width, (currLocation.y - firstLocation.y)/self.bounds.size.height);
    delta = CGPointMake((currLocation.x-25)/(self.bounds.size.width-50), (currLocation.y-25)/(self.bounds.size.height-50));
    //NSLog(@"delta=%@", NSStringFromCGPoint(delta));
    
    delta.x = delta.x < 0 ? 0 : delta.x;
    delta.x = delta.x > 1 ? 1 : delta.x;
    delta.y = delta.y < 0 ? 0 : delta.y;
    delta.y = delta.y > 1 ? 1 : delta.y;    
    //NSLog(@"delta=%@", NSStringFromCGPoint(delta));
    
    if (delegate){
        [delegate joystick:self moved:delta];
    }else{
        NSLog(@"JoystickViewController.touchesMoved:withEvent:  delegate is nil!");
    }
    
    currLocation.x = (delta.x * (self.bounds.size.width-50)) + 25;
    currLocation.y = (delta.y * (self.bounds.size.height-50)) + 25;
    
    stick.center = currLocation;
    
}

- (void)resetJoystick{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        stick.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);        
    } completion:^(BOOL finished) {
        //do nothing
    }];
}

@end
