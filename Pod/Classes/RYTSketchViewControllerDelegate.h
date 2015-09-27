//
//  RYTSketchViewDelegate.h
//  RYTSketchView
//
//  Created by Ryan Tan on 12/18/11.
//  Copyright (c) 2011 Ryan Tan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RYTSketchView;

@protocol RYTSketchViewControllerDelegate <NSObject>

- (RYTSketchView *)sketchView;
- (void)dismissAllPopovers;

- (void)reloadOptionButtons;

- (void)setCustomer:(NSDictionary*)userInfo;



- (void)clearSketch;
- (void)copySketchTapped:(id)sender;
- (void)pasteSketchTapped:(id)sender;
- (void)sketchOptionsCameraTapped:(id)sender;

@end
