//
//  NSString+TruncateToWidth.h
//  RYTSketchView
//
//  Created by Ryan Tan on 5/15/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TruncateToWidth)

- (NSString*)stringByTruncatingToWidth:(CGFloat)width withFont:(UIFont *)font;

@end
