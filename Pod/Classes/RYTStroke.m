//
//  RYTStroke.m
//  RYTSketchView
//
//  Created by Ryan on 26/9/15.
//
//

#import "RYTStroke.h"

@interface RYTStroke () {
    
}
@end

@implementation RYTStroke

@synthesize strokeColor = _strokeColor;
@synthesize lineWidth = _lineWidth;
@synthesize points = _points;

@synthesize isErasing;
@synthesize ignored;
@synthesize touchKey;

// initialize the Stroke object
- (id)init {
    // if the superclass properly initializes
    if (self = [super init]) {
        _points = [[NSMutableArray alloc] init]; // initialize points
        _strokeColor = [UIColor blackColor]; // set default color
    } // end if
    
    return self; // return this object
}

// Add a new point to the Stroke
- (void)addPoint:(CGPoint)point {
    if (self.ignored) return;
    
    // encode the point in an NSValue so we can put it in an NSArray
    NSValue *value =
    [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
    [_points addObject:value]; // add the encoded point to the NSArray
}

- (CGRect)getRect{
    
    CGFloat minX = [((NSValue *)_points[0]) CGPointValue].x;
    CGFloat minY = [((NSValue *)_points[0]) CGPointValue].y;
    CGFloat maxX = minX;
    CGFloat maxY = minY;
    
    CGPoint p;
    for (NSValue *v in _points) {
        p = [v CGPointValue];
        if (p.x < minX){
            minX = p.x;
        }else if (p.x > maxX){
            maxX = p.x;
        }
        if (p.y < minY){
            minY = p.y;
        }else if (p.y > maxY){
            maxY = p.y;
        }
        
    }
    
    minX -= 10;
    minY -= 10;
    maxX += 10;
    maxY += 10;
    
    /*
     CGPoint current = [((NSValue *)[points objectAtIndex:0]) CGPointValue];
     CGPoint previous = [((NSValue *)[points objectAtIndex:(points.count-1)]) CGPointValue];
     
     // Create two points: one with the smaller x and y values and one
     // with the larger. This is used to determine exactly where on the
     // screen needs to be redrawn.
     CGPoint lower, higher;
     lower.x = (previous.x > current.x ? current.x : previous.x);
     lower.y = (previous.y > current.y ? current.y : previous.y);
     higher.x = (previous.x < current.x ? current.x : previous.x);
     higher.y = (previous.y < current.y ? current.y : previous.y);
     
     lower.x -= 10;
     lower.y -= 10;
     higher.x += 10;
     higher.y += 10;
     
     // redraw the screen in the required region
     return CGRectMake(lower.x-lineWidth,
     lower.y-lineWidth,
     higher.x - lower.x + lineWidth*2,
     higher.y - lower.y + lineWidth * 2);
     */
    return CGRectMake(minX, minY, maxX-minX, maxY-minY);
    
}

@end
