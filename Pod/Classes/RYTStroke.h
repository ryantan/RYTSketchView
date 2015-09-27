//
//  RYTStroke.h
//  Pods
//
//  RYTStroke represents the points, color and width of one line.
//
//  Created by Ryan on 26/9/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RYTStroke : NSObject

@property (strong) UIColor* strokeColor;
@property (assign) CGFloat lineWidth;
@property (nonatomic, readonly) NSMutableArray *points;

@property (assign) BOOL isErasing;
@property (assign) BOOL ignored;
@property (nonatomic, strong) NSString *touchKey;

- (void)addPoint:(CGPoint)point; // adds a new point to the Stroke
- (CGRect)getRect;

@end
