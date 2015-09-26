// Stroke.h
// Class Stroke represents the points, color and width of one line.
// Implementation in Stroke.m
#import <UIKit/UIKit.h>

@interface Stroke : NSObject
{
   NSMutableArray *points; // the points that make up the Stroke
   UIColor *strokeColor; // the color of this Stroke
   float lineWidth; // the line width for this Stroke
} // end instance variable declaration

// declare strokeColor,lineWidth and points as properties
@property (strong) UIColor* strokeColor;
@property (assign) float lineWidth;
@property (nonatomic, readonly) NSMutableArray *points;

@property (assign) BOOL isErasing;
@property (assign) BOOL ignored;
@property (nonatomic, strong) NSString *touchKey;

- (void)addPoint:(CGPoint)point; // adds a new point to the Stroke
- (CGRect)getRect;
@end // end interface Stroke
