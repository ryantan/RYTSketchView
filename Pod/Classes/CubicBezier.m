//
//  CubicBezier.m
//  RYTSketchView
//
//  Created by Ryan Tan on 10/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CubicBezier.h"

@implementation CubicBezier

//@synthesize showControlPoints;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


extern float distanceBetweenPoints(CGPoint pointA, CGPoint pointB){
    CGFloat deltaX = pointB.x - pointA.x;
    CGFloat deltaY = pointB.y - pointA.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
}

extern float distanceBetweenPointsSquared(CGPoint pointA, CGPoint pointB){
    CGFloat deltaX = pointB.x - pointA.x;
    CGFloat deltaY = pointB.y - pointA.y;
    return deltaX*deltaX + deltaY*deltaY;
}

/*
extern float distanceBetweenPoints_old(CGPoint pointA, CGPoint pointB){
    //NSLog(@"distanceBetweenPoints");
    //NSLog(@"  pointA = %@", NSStringFromCGPoint(pointA));
    //NSLog(@"  pointB = %@", NSStringFromCGPoint(pointB));
    //NSLog(@"  (pointB.x-pointA.x) = %f", (pointB.x-pointA.x));
    //NSLog(@"  (pointB.y-pointA.y) = %f", (pointB.y-pointA.y));
    float dist = sqrtf(((pointB.x-pointA.x)*(pointB.x-pointA.x)) + ((pointB.y-pointA.y)*(pointB.y-pointA.y)));
    //NSLog(@"  dist = %f", dist);
    return dist;
}
*/

extern float approx_distance( SInt32 dx, SInt32 dy ) {
    UInt32 min, max, approx;
    
    if ( dx < 0 ) dx = -dx;
    if ( dy < 0 ) dy = -dy;
    
    if ( dx < dy )
    {
        min = dx;
        max = dy;
    } else {
        min = dy;
        max = dx;
    }
    
    approx = ( max * 1007 ) + ( min * 441 );
    if ( max < ( min << 4 ))
        approx -= ( max * 40 );
    
    // add 512 for proper rounding
    return (( approx + 512 ) >> 10 );
} 


+ (CGPoint) normalize:(CGPoint)point to:(float)d {
    //NSLog(@"normalize %@ to %f", NSStringFromCGPoint(point), d);

    float distance = sqrt(point.x*point.x + point.y*point.y);
    //NSLog(@"  distance = %f", distance);

    if (distance == 0) {
        //this is not normal and hopefully will go away when other bugs are fixed
        NSLog(@"div by 0 in normalize");
        return CGPointMake(point.x, point.y);
    }
    float newX = (point.x/distance)*d;
    float newY = (point.y/distance)*d;
    CGPoint newP = CGPointMake(newX, newY);
    //NSLog(@"  newP = %@", NSStringFromCGPoint(newP));

    return newP;
}


extern CGPoint offset(CGPoint p, float x, float y) {
    return CGPointMake(p.x+x, p.y+y);
}

extern CGPoint polar(float distance, float angle){
    return CGPointMake(distance*cos(angle),distance*sin(angle));
}



static void drawCurve(CGContextRef g, CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4){
    /*
    UIBezierPath bezier = [UIBezierPath bezierPath]; // BezierSegment(p1,p2,p3,p4);	// BezierSegment using the four points
    g.moveTo(p1.x,p1.y);
    // Construct the curve out of 100 segments (adjust number for less/more detail)
    for (var t=.01;t<1.01;t+=.01){
        var val = bezier.getValue(t);	// x,y on the curve for a given t
        g.lineTo(val.x,val.y);
    }
    */
}

+ (void) curveThroughPoints:(NSArray *)points context:(CGContextRef)context showControlPoints:(bool)showControlPoints{
    [CubicBezier curveThroughPoints:points context:context z:0.5 angleFactor:0.75 moveTo:TRUE showControlPoints:showControlPoints];
}

/* public static function curveThroughPoints
 *	Draws a smooth curve through a series of points. For a closed curve, make the first and last points the same.
 *	@param:
 *		(CGContextRef)context   -context on which to draw the curve
 *		(NSArray *)points       -Array of Point instances
 *		(float)z                -A factor (between 0 and 1) to reduce the size of curves by limiting the distance of control points from anchor points.
 *                               For example, z=.5 limits control points to half the distance of the closer adjacent anchor point.
 *                               I put the option here, but I recommend sticking with .5
 *		(float)angleFactor      -Adjusts the size of curves depending on how acute the angle between points is. Curves are reduced as acuteness
 *                               increases, and this factor controls by how much.
 *                               1 = curves are reduced in direct proportion to acuteness
 *                               0 = curves are not reduced at all based on acuteness
 *                               in between = the reduction is basically a percentage of the full reduction
 *		(bool)moveTo            -Specifies whether to move to the first point in the curve rather than continuing drawing
 *                               from wherever drawing left off.
 *	@return:
 */	


//z = 0.5 : (own interpretation) controls the pull factor the points have, i.e. the higher the value of z, the further the before & after control points are from each point (rounder)
//angleFactor = 0.75
//moveTo = TRUE
+ (void) curveThroughPoints:(NSArray *)points context:(CGContextRef)context z:(float)z angleFactor:(float)angleFactor moveTo:(bool)moveTo showControlPoints:(bool)showControlPoints {

    CFTimeInterval time_start = CFAbsoluteTimeGetCurrent();
    CFTimeInterval time_after_processing_points;
    CFTimeInterval time_after_processing_control_points;
    CFTimeInterval time_after_drawing_points;
    
    
    
    
    //NSMutableArray *p = [[NSMutableArray alloc] initWithArray:points];	// Local copy of points array
    CGPoint * pTemp;
    CGPoint * p;
    int pCount = 0;
    
    NSLog(@"points.count=%lu",(unsigned long)points.count);
    float smallestDistance = 16;
    //if (points.count < 10) smallestDistance = 5;
    //if (points.count > 30) smallestDistance = 64;
    //NSMutableArray *duplicates = [[NSMutableArray alloc] initWithCapacity:points.count/2];	// Array to hold indices of duplicate points
    //int * duplicates = malloc(sizeof(int) * points.count);
    //int duplicateCount = 0;
    
    pTemp = malloc(sizeof(CGPoint) * points.count + 1); //1 extra position for nil at the end
    
    CGPoint tempP1, tempP2;
    bool registerPoint = FALSE;
    bool check_for_smallest_distance = FALSE;
    // Check to make sure array contains only Points
    for (int i=0; i<points.count; i++){
        registerPoint = FALSE;
        /*
        if (!(p[i] is Point)){
            throw new Error("Array must contain Point objects");
        }
        */
        // Check for the same point twice in a row
        tempP1 = [[points objectAtIndex:i] CGPointValue];
        if (i > 0){
            tempP2 = [[points objectAtIndex:i-1] CGPointValue];
            if (tempP1.x == tempP2.x && tempP1.y == tempP2.y){
                //is duplicate
            }else{
                // not duplicate
                //check distance from last point
                
                //may be faster to skip this check
                if (check_for_smallest_distance){
                    
                    float d = distanceBetweenPoints(tempP1, pTemp[pCount-1]);
                    
                    if (d >= smallestDistance){
                        registerPoint = true;
                    }
                    NSLog(@"d=%f, registerPoint=%@",d, (registerPoint?@"YES":@"NO"));   
                }else{
                    registerPoint = TRUE;
                }
            }
        }else{
            // always register first point
            registerPoint = true;
        }
        
        if (registerPoint) {
            pTemp[pCount] = tempP1;
            pCount++;
        }
    }
    
    
    if (pCount == 0){
        free(pTemp);
        return;
    }
    
    p = malloc(sizeof(CGPoint) * pCount); 
    
    for (int i=0; i<pCount; i++){
        p[i] = pTemp[i];
    }
    free(pTemp);
    
    /*
    // Loop through duplicates array and remove points from the points array
    for (int i=duplicates.count-1; i>=0; i--){
        [p removeObjectAtIndex:[[duplicates objectAtIndex:i] intValue]];
    }
    */        

    // Make sure z is between 0 and 1 (too messy otherwise)
    if (z <= 0){
        z = .5;
    } else if (z > 1){
        z = 1;
    }
    // Make sure angleFactor is between 0 and 1
    if (angleFactor < 0){
        angleFactor = 0;
    } else if (angleFactor > 1){
        angleFactor = 1;
    }
    
    time_after_processing_points = CFAbsoluteTimeGetCurrent();
        
    //
    // First calculate all the curve control points
    //
    
    NSLog(@"pCount=%d",pCount);
    //return;
    
    // None of this junk will do any good if there are only two points
    if (pCount > 2){
        // Ordinarily, curve calculations will start with the second point and go through the second-to-last point
        int firstPt = 1;
        int lastPt = pCount-1;
        // Check if this is a closed line (the first and last points are the same)
        if (p[0].x == p[lastPt].x && p[0].y == p[lastPt].y){
            // Include first and last points in curve calculations
            firstPt = 0;
            lastPt = pCount;
        }
        
        
        //CGPoint *controlPts = malloc(sizeof(CGPoint) * pCount * 2);	// An array to store the two control points (of a cubic Bézier curve) for each point
        CGPoint *controlPtsA = malloc(sizeof(CGPoint) * pCount);	// An array to store the first control points (of a cubic Bézier curve) for each point
        CGPoint *controlPtsB = malloc(sizeof(CGPoint) * pCount);	// An array to store the second control points (of a cubic Bézier curve) for each point
        
        
        for (int i=0; i<pCount; i++) {
            NSLog(@"p[%d] = %@", i, NSStringFromCGPoint(p[i]));
        }

        
        
        // Loop through all the points (except the first and last if not a closed line) to get curve control points for each.
        for (int i=firstPt; i<lastPt; i++) {
            
            // The previous, current, and next points
            CGPoint p0 = (i-1 < 0) ? p[pCount-2] : p[i-1];	// If the first point (of a closed line), use the second-to-last point as the previous point
            CGPoint p1 = p[i];
            CGPoint p2 = (i+1 == pCount) ? p[1] : p[i+1];		// If the last point (of a closed line), use the second point as the next point
            float a = distanceBetweenPoints(p0,p1);	// Distance from previous point to current point
            if (a < 0.001) a = .001;		// Correct for near-zero distances, a cheap way to prevent division by zero
            float b = distanceBetweenPoints(p1,p2);	// Distance from current point to next point
            if (b < 0.001) b = .001;
            float c = distanceBetweenPoints(p0,p2);	// Distance from previous point to next point
            if (c < 0.001) c = .001;
            
            // find cos of middle angle
            float cos = (b*b+a*a-c*c)/(2*b*a);
            // Make sure above value is between -1 and 1 so that Math.acos will work
            if (cos < -1) cos = -1;
            else if (cos > 1) cos = 1;
            //NSLog(@"cos = %f", cos);
            
            float C = acosf(cos);	// Angle formed by the two sides of the triangle (described by the three points above) adjacent to the current point
            //NSLog(@"C = %f", C);
            
            // Duplicate set of points. Start by giving previous and next points values RELATIVE to the current point.
            CGPoint aPt = CGPointMake(p0.x-p1.x,p0.y-p1.y);
            CGPoint bPt = CGPointMake(p1.x,p1.y);
            CGPoint cPt = CGPointMake(p2.x-p1.x,p2.y-p1.y);
            
            
            /*if (i == firstPt){
                //NSLog(@"p0 = %@",NSStringFromCGPoint(p0));
                //NSLog(@"p1 = %@",NSStringFromCGPoint(p1));
                //NSLog(@"p2 = %@",NSStringFromCGPoint(p2));
                
                //NSLog(@"a = %f", a);
                //NSLog(@"b = %f", b);
                //NSLog(@"c = %f", c);

                //NSLog(@"aPt = %@",NSStringFromCGPoint(aPt));
                //NSLog(@"bPt = %@",NSStringFromCGPoint(bPt));
                //NSLog(@"cPt = %@",NSStringFromCGPoint(cPt));
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
                CGContextMoveToPoint(context, p1.x, p1.y);
                CGContextAddLineToPoint(context, p2.x, p2.y);
                CGContextMoveToPoint(context, p1.x, p1.y);
                CGContextAddLineToPoint(context, p0.x, p0.y);
                CGContextStrokePath(context);

            }*/

            
            
            /*
             We'll be adding the vectors from the previous and next points to the current point,
             but we don't want differing magnitudes (i.e. line segment lengths) to affect the direction
             of the new vector. Therefore we make sure the segments we use, based on the duplicate points
             created above, are of equal length. The angle of the new vector will thus bisect angle C
             (defined above) and the perpendicular to this is nice for the line tangent to the curve.
             The curve control points will be along that tangent line.
             */
            if (a > b){
                aPt = [self normalize:aPt to:b];	// Scale the segment to aPt (bPt to aPt) to the size of b (bPt to cPt) if b is shorter.
            } else if (b > a){
                cPt = [self normalize:cPt to:a];	// Scale the segment to cPt (bPt to cPt) to the size of a (aPt to bPt) if a is shorter.
            }
            // Offset aPt and cPt by the current point to get them back to their absolute position.
            
            
            aPt = offset(aPt, p1.x, p1.y);
            cPt = offset(cPt, p1.x, p1.y);            
            
            /*CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
            CGContextStrokeRect(context, CGRectMake(aPt.x, aPt.y, 3, 3));
            CGContextSetRGBStrokeColor(context, 1, 0, 1, 1);
            CGContextStrokeRect(context, CGRectMake(cPt.x, cPt.y, 3, 3));*/
            
            
            
            // Get the sum of the two vectors, which is perpendicular to the line along which our curve control points will lie.
            float ax = bPt.x-aPt.x;	// x component of the segment from previous to current point
            float ay = bPt.y-aPt.y;
            
            float bx = cPt.x - bPt.x;	// x component of the segment from next to current point
            float by = cPt.y - bPt.y;
            float rx = ax - bx;	// resultant of x components
            float ry = ay - by;
            
            // Correct for three points in a line by finding the angle between just two of them
            if (rx == 0 && ry == 0){
                rx = bx;
                ry = by;
            }
            // Switch rx and ry when y or x difference is 0. This seems to prevent the angle from being perpendicular to what it should be.
            if (ay == 0 && by == 0){
                rx = 0;
                ry = 1;
            } else if (ax == 0 && bx == 0){
                rx = 1;
                ry = 0;
            }
            // End of Correct for three points in a line...
            
            //float r = sqrt(rx*rx+ry*ry);	// length of the summed vector - not being used, but there it is anyway
            
            //atan2 returns atan of para2/para1
            float theta = atan2(ry,rx);	// angle of the new vector
            
            float controlDist = MIN(a,b)*z;	// Distance of curve control points from current point: a fraction of the length of the shorter adjacent triangle side
            float controlScaleFactor = C/M_PI;	// Scale the distance based on the acuteness of the angle. Prevents big loops around long, sharp-angled triangles.
            controlDist *= ((1-angleFactor) + angleFactor*controlScaleFactor);	// Mess with this for some fine-tuning
            float controlAngle = theta+M_PI/2;	// The angle from the current point to control points: the new vector angle plus 90 degrees (tangent to the curve).
            CGPoint controlPoint2 = polar(controlDist,controlAngle);	// Control point 2, curving to the next point.
            CGPoint controlPoint1 = polar(controlDist,controlAngle+M_PI);	// Control point 1, curving from the previous point (180 degrees away from control point 2).
            // Offset control points to put them in the correct absolute position
            controlPoint1 = offset(controlPoint1, p1.x, p1.y);
            controlPoint2 = offset(controlPoint2, p1.x, p1.y);
            
            
            /*
             Haven't quite worked out how this happens, but some control points will be reversed.
             In this case controlPoint2 will be farther from the next point than controlPoint1 is.
             Check for that and switch them if it's true.
             */
            if (distanceBetweenPoints(controlPoint2,p2) > distanceBetweenPoints(controlPoint1,p2)){
                //controlPts[i] = new Array(controlPoint2,controlPoint1);	// Add the two control points to the array in reverse order
                controlPtsA[i] = controlPoint2;
                controlPtsB[i] = controlPoint1;
            } else {
                //controlPts[i] = new Array(controlPoint1,controlPoint2);	// Otherwise add the two control points to the array in normal order
                controlPtsA[i] = controlPoint1;
                controlPtsB[i] = controlPoint2;
            }
            
            //For debug testing only, remove afer use;
            //controlPtsB[i] = CGPointMake(controlPtsB[i].x, controlPtsB[i].y+20);
            
            
            if (showControlPoints){
                // Uncomment to draw lines showing where the control points are.
                
                //NSLog(@"controlPoint1 = %@",NSStringFromCGPoint(controlPoint1));
                //NSLog(@"controlPoint2 = %@",NSStringFromCGPoint(controlPoint2));
                
                CGContextSetLineWidth(context, 2);
                CGContextSetRGBStrokeColor(context, 0, 0, 0, .6);
                CGContextStrokeRect(context, CGRectMake(p1.x-4, p1.y-4, 8, 8));
                
                CGContextSetLineWidth(context, 6);
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPoint2.x, controlPoint2.y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .1);
                CGContextMoveToPoint(context, p1.x,p1.y);
                CGContextAddLineToPoint(context, controlPoint2.x,controlPoint2.y);
                CGContextStrokePath(context);
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPoint1.x, controlPoint1.y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .1);
                CGContextMoveToPoint(context, p1.x,p1.y);
                CGContextAddLineToPoint(context, controlPoint1.x,controlPoint1.y);
                CGContextStrokePath(context);
            }
            

        }
        
        
        /*
        //
        // Now draw the curve
        //
        // If moveTo condition is false, this curve can connect to a previous curve on the same graphics.
        if (moveTo) g.moveTo(p[0].x, p[0].y);
        else g.lineTo(p[0].x, p[0].y);
        // If this isn't a closed line
        if (firstPt == 1){
            // Draw a regular quadratic Bézier curve from the first to second points, using the first control point of the second point
            g.curveTo(controlPts[1][0].x,controlPts[1][0].y,p[1].x,p[1].y);
        }
        var straightLines:Boolean = true;	// Change to true if you want to use lineTo for straight lines of 3 or more points rather than curves. You'll get straight lines but possible sharp corners!
        // Loop through points to draw cubic Bézier curves through the penultimate point, or through the last point if the line is closed.
        for (i=firstPt;i<lastPt-1;i++){
            // Determine if multiple points in a row are in a straight line
            var isStraight:Boolean = ( ( i > 0 && Math.atan2(p[i].y-p[i-1].y,p[i].x-p[i-1].x) == Math.atan2(p[i+1].y-p[i].y,p[i+1].x-p[i].x) ) || ( i < p.length - 2 && Math.atan2(p[i+2].y-p[i+1].y,p[i+2].x-p[i+1].x) == Math.atan2(p[i+1].y-p[i].y,p[i+1].x-p[i].x) ) );
            if (straightLines && isStraight){
                g.lineTo(p[i+1].x,p[i+1].y);
            } else {
                // BezierSegment instance using the current point, its second control point, the next point's first control point, and the next point
                var bezier:BezierSegment = new BezierSegment(p[i],controlPts[i][1],controlPts[i+1][0],p[i+1]);
                // Construct the curve out of 100 segments (adjust number for less/more detail)
                for (var t=.01;t<1.01;t+=.01){
                    var val = bezier.getValue(t);	// x,y on the curve for a given t
                    g.lineTo(val.x,val.y);
                }
            }
        }
        // If this isn't a closed line
        if (lastPt == p.length-1){
            // Curve to the last point using the second control point of the penultimate point.
            g.curveTo(controlPts[i][1].x,controlPts[i][1].y,p[i+1].x,p[i+1].y);
        }
        */
        
        time_after_processing_control_points = CFAbsoluteTimeGetCurrent();
        
        UIBezierPath *bPath = [UIBezierPath bezierPath];
        [bPath moveToPoint:p[0]];
        bPath.lineWidth=1.5;
        
        //bPath.lineCapStyle = kCGLineCapRound;
        //bPath.lineJoinStyle = kCGLineJoinRound;
        //bPath.flatness = 0.2;
        
        
        for (int i=firstPt+1; i<lastPt; i++) {
            [bPath addCurveToPoint:p[i] controlPoint1:controlPtsB[i-1] controlPoint2:controlPtsA[i]];
            
            if (showControlPoints){
                CGContextSetLineWidth(context, 2);
                CGContextSetRGBStrokeColor(context, 0, 0, 0, .6);
                CGContextStrokeRect(context, CGRectMake(p[i].x-4, p[i].y-4, 8, 8));
                
                CGContextSetLineWidth(context, 6);
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPtsB[i-1].x, controlPtsB[i-1].y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .1);
                CGContextMoveToPoint(context, p[i-1].x,p[i-1].y);
                CGContextAddLineToPoint(context, controlPtsB[i-1].x,controlPtsB[i-1].y);
                CGContextStrokePath(context);
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPtsA[i].x, controlPtsA[i].y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .1);
                CGContextMoveToPoint(context, p[i].x,p[i].y);
                CGContextAddLineToPoint(context, controlPtsA[i].x,controlPtsA[i].y);
                CGContextStrokePath(context);
            }
            
            
        }
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
        
        free(controlPtsA);
        free(controlPtsB);
        
        CGContextSetAllowsAntialiasing(context, TRUE);
        CGContextSetShouldAntialias(context, TRUE);
        
        //Both of these works:
        //1.) Stroke bPath directly
        //CGContextSaveGState(context);
        [bPath stroke];
        //CGContextRestoreGState(context);
        
        /*
        //2. Add bPath to context, then call CGContextStrokePath on context
        CGContextAddPath(context, CGPathCreateCopy(bPath.CGPath));
        CGContextStrokePath(context);
        */
        
        
        time_after_drawing_points = CFAbsoluteTimeGetCurrent();
        
        if(pCount > 5){
            if (time_after_drawing_points > 0){
                CFTimeInterval time_for_processing_points = time_after_processing_points - time_start;
                CFTimeInterval time_for_processing_control_points = time_after_processing_control_points - time_after_processing_points;
                CFTimeInterval time_for_drawing = time_after_drawing_points - time_after_processing_control_points;
                CFTimeInterval time_total = time_after_drawing_points - time_start;
                
                NSLog(@"Total Time elapsed: %g", time_total);
                NSLog(@"Time elapsed for processing points: %g (%g%%)", time_for_processing_points, (time_for_processing_points/time_total*100));
                NSLog(@"Time elapsed for processing control points: %g (%g%%)", time_for_processing_control_points, (time_for_processing_control_points/time_total*100));
                NSLog(@"Time elapsed for drawing: %g (%g%%)", time_for_drawing, (time_for_drawing/time_total*100));
            } 
        }
           
        
    } else if (pCount == 2){	
        // just draw a line if only two points
        NSLog(@"just draw a line if only two points");
        CGContextMoveToPoint(context, p[0].x,p[0].y);
        CGContextAddLineToPoint(context, p[1].x,p[1].y);
    }
    
    free(p);
    
    
    //What is this line for? Consider comment away
    //CGContextStrokePath(context);
}


+ (void) curveThroughPointsOld:(NSArray *)points context:(CGContextRef)context z:(float)z angleFactor:(float)angleFactor moveTo:(bool)moveTo showControlPoints:(bool)showControlPoints {
    
    CFTimeInterval time_start = CFAbsoluteTimeGetCurrent();
    CFTimeInterval time_after_processing_points;
    CFTimeInterval time_after_drawing_points;
    
    
    
    
    //NSMutableArray *p = [[NSMutableArray alloc] initWithArray:points];	// Local copy of points array
    CGPoint * pTemp;
    CGPoint * p;
    int pCount = 0;
    
    NSLog(@"points.count=%lu",(unsigned long)points.count);
    float smallestDistance = 16;
    //if (points.count < 10) smallestDistance = 5;
    //if (points.count > 30) smallestDistance = 64;
    //NSMutableArray *duplicates = [[NSMutableArray alloc] initWithCapacity:points.count/2];	// Array to hold indices of duplicate points
    //int * duplicates = malloc(sizeof(int) * points.count);
    //int duplicateCount = 0;
    
    pTemp = malloc(sizeof(CGPoint) * points.count + 1); //1 extra position for nil at the end
    
    CGPoint tempP1, tempP2;
    bool registerPoint = FALSE;
    // Check to make sure array contains only Points
    for (int i=0; i<points.count; i++){
        registerPoint = FALSE;
        /*
         if (!(p[i] is Point)){
         throw new Error("Array must contain Point objects");
         }
         */
        // Check for the same point twice in a row
        tempP1 = [[points objectAtIndex:i] CGPointValue];
        if (i > 0){
            tempP2 = [[points objectAtIndex:i-1] CGPointValue];
            if (tempP1.x == tempP2.x && tempP1.y == tempP2.y){
                //is duplicate
            }else{
                // not duplicate
                //check distance from last point
                float d = distanceBetweenPoints(tempP1, pTemp[pCount-1]);
                
                if (d >= smallestDistance){
                    registerPoint = true;
                }
                NSLog(@"d=%f, registerPoint=%@",d, (registerPoint?@"YES":@"NO"));
            }
        }else{
            // always register first point
            registerPoint = true;
        }
        
        if (registerPoint) {
            pTemp[pCount] = tempP1;
            pCount++;
        }
    }
    
    if (pCount == 0){
        free(pTemp);
        return;
    }
    
    p = malloc(sizeof(CGPoint) * pCount); 
    
    for (int i=0; i<pCount; i++){
        p[i] = pTemp[i];
    }
    free(pTemp);
    
    
    /*
     // Loop through duplicates array and remove points from the points array
     for (int i=duplicates.count-1; i>=0; i--){
     [p removeObjectAtIndex:[[duplicates objectAtIndex:i] intValue]];
     }
     */        
    
    // Make sure z is between 0 and 1 (too messy otherwise)
    if (z <= 0){
        z = .5;
    } else if (z > 1){
        z = 1;
    }
    // Make sure angleFactor is between 0 and 1
    if (angleFactor < 0){
        angleFactor = 0;
    } else if (angleFactor > 1){
        angleFactor = 1;
    }
    
    
    
    //
    // First calculate all the curve control points
    //
    
    NSLog(@"pCount=%d",pCount);
    //return;
    
    // None of this junk will do any good if there are only two points
    if (pCount > 2){
        // Ordinarily, curve calculations will start with the second point and go through the second-to-last point
        int firstPt = 1;
        int lastPt = pCount-1;
        // Check if this is a closed line (the first and last points are the same)
        if (p[0].x == p[lastPt].x && p[0].y == p[lastPt].y){
            // Include first and last points in curve calculations
            firstPt = 0;
            lastPt = pCount;
        }
        
        
        //CGPoint *controlPts = malloc(sizeof(CGPoint) * pCount * 2);	// An array to store the two control points (of a cubic Bézier curve) for each point
        CGPoint *controlPtsA = malloc(sizeof(CGPoint) * pCount);	// An array to store the first control points (of a cubic Bézier curve) for each point
        CGPoint *controlPtsB = malloc(sizeof(CGPoint) * pCount);	// An array to store the second control points (of a cubic Bézier curve) for each point
        
        
        for (int i=0; i<pCount; i++) {
            NSLog(@"p[%d] = %@", i, NSStringFromCGPoint(p[i]));
        }
        
        
        
        // Loop through all the points (except the first and last if not a closed line) to get curve control points for each.
        for (int i=firstPt; i<lastPt; i++) {
            
            // The previous, current, and next points
            CGPoint p0 = (i-1 < 0) ? p[pCount-2] : p[i-1];	// If the first point (of a closed line), use the second-to-last point as the previous point
            CGPoint p1 = p[i];
            CGPoint p2 = (i+1 == pCount) ? p[1] : p[i+1];		// If the last point (of a closed line), use the second point as the next point
            float a = distanceBetweenPoints(p0,p1);	// Distance from previous point to current point
            if (a < 0.001) a = .001;		// Correct for near-zero distances, a cheap way to prevent division by zero
            float b = distanceBetweenPoints(p1,p2);	// Distance from current point to next point
            if (b < 0.001) b = .001;
            float c = distanceBetweenPoints(p0,p2);	// Distance from previous point to next point
            if (c < 0.001) c = .001;
            
            // find cos of middle angle
            float cos = (b*b+a*a-c*c)/(2*b*a);
            // Make sure above value is between -1 and 1 so that Math.acos will work
            if (cos < -1) cos = -1;
            else if (cos > 1) cos = 1;
            //NSLog(@"cos = %f", cos);
            
            float C = acosf(cos);	// Angle formed by the two sides of the triangle (described by the three points above) adjacent to the current point
                                    //NSLog(@"C = %f", C);
            
            // Duplicate set of points. Start by giving previous and next points values RELATIVE to the current point.
            CGPoint aPt = CGPointMake(p0.x-p1.x,p0.y-p1.y);
            CGPoint bPt = CGPointMake(p1.x,p1.y);
            CGPoint cPt = CGPointMake(p2.x-p1.x,p2.y-p1.y);
            
            
            /*if (i == firstPt){
             //NSLog(@"p0 = %@",NSStringFromCGPoint(p0));
             //NSLog(@"p1 = %@",NSStringFromCGPoint(p1));
             //NSLog(@"p2 = %@",NSStringFromCGPoint(p2));
             
             //NSLog(@"a = %f", a);
             //NSLog(@"b = %f", b);
             //NSLog(@"c = %f", c);
             
             //NSLog(@"aPt = %@",NSStringFromCGPoint(aPt));
             //NSLog(@"bPt = %@",NSStringFromCGPoint(bPt));
             //NSLog(@"cPt = %@",NSStringFromCGPoint(cPt));
             
             CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
             CGContextMoveToPoint(context, p1.x, p1.y);
             CGContextAddLineToPoint(context, p2.x, p2.y);
             CGContextMoveToPoint(context, p1.x, p1.y);
             CGContextAddLineToPoint(context, p0.x, p0.y);
             CGContextStrokePath(context);
             
             }*/
            
            
            
            /*
             We'll be adding the vectors from the previous and next points to the current point,
             but we don't want differing magnitudes (i.e. line segment lengths) to affect the direction
             of the new vector. Therefore we make sure the segments we use, based on the duplicate points
             created above, are of equal length. The angle of the new vector will thus bisect angle C
             (defined above) and the perpendicular to this is nice for the line tangent to the curve.
             The curve control points will be along that tangent line.
             */
            if (a > b){
                aPt = [self normalize:aPt to:b];	// Scale the segment to aPt (bPt to aPt) to the size of b (bPt to cPt) if b is shorter.
            } else if (b > a){
                cPt = [self normalize:cPt to:a];	// Scale the segment to cPt (bPt to cPt) to the size of a (aPt to bPt) if a is shorter.
            }
            // Offset aPt and cPt by the current point to get them back to their absolute position.
            
            
            aPt = offset(aPt, p1.x, p1.y);
            cPt = offset(cPt, p1.x, p1.y);            
            
            /*CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
             CGContextStrokeRect(context, CGRectMake(aPt.x, aPt.y, 3, 3));
             CGContextSetRGBStrokeColor(context, 1, 0, 1, 1);
             CGContextStrokeRect(context, CGRectMake(cPt.x, cPt.y, 3, 3));*/
            
            
            
            // Get the sum of the two vectors, which is perpendicular to the line along which our curve control points will lie.
            float ax = bPt.x-aPt.x;	// x component of the segment from previous to current point
            float ay = bPt.y-aPt.y;
            
            //shouldn't this be cPt.x-bPt.x ?
            float bx = bPt.x-cPt.x;	// x component of the segment from next to current point
            float by = bPt.y-cPt.y;
            float rx = ax + bx;	// sum of x components
            float ry = ay + by;
            
            // Correct for three points in a line by finding the angle between just two of them
            if (rx == 0 && ry == 0){
                //this may be because cPt.x-bPt.x was flipped by mistake above
                rx = -bx;	// Really not sure why this seems to have to be negative
                ry = by;
            }
            // Switch rx and ry when y or x difference is 0. This seems to prevent the angle from being perpendicular to what it should be.
            if (ay == 0 && by == 0){
                rx = 0;
                ry = 1;
            } else if (ax == 0 && bx == 0){
                rx = 1;
                ry = 0;
            }
            // End of Correct for three points in a line...
            
            //float r = sqrt(rx*rx+ry*ry);	// length of the summed vector - not being used, but there it is anyway
            
            //atan2 returns atan of para2/para1
            float theta = atan2(ry,rx);	// angle of the new vector
            
            float controlDist = MIN(a,b)*z;	// Distance of curve control points from current point: a fraction the length of the shorter adjacent triangle side
            float controlScaleFactor = C/M_PI;	// Scale the distance based on the acuteness of the angle. Prevents big loops around long, sharp-angled triangles.
            controlDist *= ((1-angleFactor) + angleFactor*controlScaleFactor);	// Mess with this for some fine-tuning
            float controlAngle = theta+M_PI/2;	// The angle from the current point to control points: the new vector angle plus 90 degrees (tangent to the curve).
            CGPoint controlPoint2 = polar(controlDist,controlAngle);	// Control point 2, curving to the next point.
            CGPoint controlPoint1 = polar(controlDist,controlAngle+M_PI);	// Control point 1, curving from the previous point (180 degrees away from control point 2).
                                                                            // Offset control points to put them in the correct absolute position
            controlPoint1 = offset(controlPoint1, p1.x, p1.y);
            controlPoint2 = offset(controlPoint2, p1.x, p1.y);
            
            
            /*
             Haven't quite worked out how this happens, but some control points will be reversed.
             In this case controlPoint2 will be farther from the next point than controlPoint1 is.
             Check for that and switch them if it's true.
             */
            if (distanceBetweenPoints(controlPoint2,p2) > distanceBetweenPoints(controlPoint1,p2)){
                //controlPts[i] = new Array(controlPoint2,controlPoint1);	// Add the two control points to the array in reverse order
                controlPtsA[i] = controlPoint2;
                controlPtsB[i] = controlPoint1;
            } else {
                //controlPts[i] = new Array(controlPoint1,controlPoint2);	// Otherwise add the two control points to the array in normal order
                controlPtsA[i] = controlPoint1;
                controlPtsB[i] = controlPoint2;
            }
            
            //For debug testing only, remove afer use;
            //controlPtsB[i] = CGPointMake(controlPtsB[i].x, controlPtsB[i].y+20);
            
            
            if (showControlPoints){
                // Uncomment to draw lines showing where the control points are.
                
                //NSLog(@"controlPoint1 = %@",NSStringFromCGPoint(controlPoint1));
                //NSLog(@"controlPoint2 = %@",NSStringFromCGPoint(controlPoint2));
                
                CGContextSetLineWidth(context, 2);
                CGContextSetRGBStrokeColor(context, 0, 0, 0, .6);
                CGContextStrokeRect(context, CGRectMake(p1.x-4, p1.y-4, 8, 8));
                
                CGContextSetLineWidth(context, 6);
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPoint2.x, controlPoint2.y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .1);
                CGContextMoveToPoint(context, p1.x,p1.y);
                CGContextAddLineToPoint(context, controlPoint2.x,controlPoint2.y);
                CGContextStrokePath(context);
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPoint1.x, controlPoint1.y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .1);
                CGContextMoveToPoint(context, p1.x,p1.y);
                CGContextAddLineToPoint(context, controlPoint1.x,controlPoint1.y);
                CGContextStrokePath(context);
            }
            
            
        }
        
        
        /*
         //
         // Now draw the curve
         //
         // If moveTo condition is false, this curve can connect to a previous curve on the same graphics.
         if (moveTo) g.moveTo(p[0].x, p[0].y);
         else g.lineTo(p[0].x, p[0].y);
         // If this isn't a closed line
         if (firstPt == 1){
         // Draw a regular quadratic Bézier curve from the first to second points, using the first control point of the second point
         g.curveTo(controlPts[1][0].x,controlPts[1][0].y,p[1].x,p[1].y);
         }
         var straightLines:Boolean = true;	// Change to true if you want to use lineTo for straight lines of 3 or more points rather than curves. You'll get straight lines but possible sharp corners!
         // Loop through points to draw cubic Bézier curves through the penultimate point, or through the last point if the line is closed.
         for (i=firstPt;i<lastPt-1;i++){
         // Determine if multiple points in a row are in a straight line
         var isStraight:Boolean = ( ( i > 0 && Math.atan2(p[i].y-p[i-1].y,p[i].x-p[i-1].x) == Math.atan2(p[i+1].y-p[i].y,p[i+1].x-p[i].x) ) || ( i < p.length - 2 && Math.atan2(p[i+2].y-p[i+1].y,p[i+2].x-p[i+1].x) == Math.atan2(p[i+1].y-p[i].y,p[i+1].x-p[i].x) ) );
         if (straightLines && isStraight){
         g.lineTo(p[i+1].x,p[i+1].y);
         } else {
         // BezierSegment instance using the current point, its second control point, the next point's first control point, and the next point
         var bezier:BezierSegment = new BezierSegment(p[i],controlPts[i][1],controlPts[i+1][0],p[i+1]);
         // Construct the curve out of 100 segments (adjust number for less/more detail)
         for (var t=.01;t<1.01;t+=.01){
         var val = bezier.getValue(t);	// x,y on the curve for a given t
         g.lineTo(val.x,val.y);
         }
         }
         }
         // If this isn't a closed line
         if (lastPt == p.length-1){
         // Curve to the last point using the second control point of the penultimate point.
         g.curveTo(controlPts[i][1].x,controlPts[i][1].y,p[i+1].x,p[i+1].y);
         }
         */
        
        time_after_processing_points = CFAbsoluteTimeGetCurrent();
        
        UIBezierPath *bPath = [UIBezierPath bezierPath];
        [bPath moveToPoint:p[0]];
        bPath.lineWidth=1.5;
        
        //bPath.lineCapStyle = kCGLineCapRound;
        //bPath.lineJoinStyle = kCGLineJoinRound;
        //bPath.flatness = 0.2;
        
        
        for (int i=firstPt+1; i<lastPt; i++) {
            [bPath addCurveToPoint:p[i] controlPoint1:controlPtsB[i-1] controlPoint2:controlPtsA[i]];
            
            if (showControlPoints){
                CGContextSetLineWidth(context, 2);
                CGContextSetRGBStrokeColor(context, 0, 0, 0, .6);
                CGContextStrokeRect(context, CGRectMake(p[i].x-4, p[i].y-4, 8, 8));
                
                CGContextSetLineWidth(context, 6);
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPtsB[i-1].x, controlPtsB[i-1].y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 1, 0, 0, .1);
                CGContextMoveToPoint(context, p[i-1].x,p[i-1].y);
                CGContextAddLineToPoint(context, controlPtsB[i-1].x,controlPtsB[i-1].y);
                CGContextStrokePath(context);
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .3);
                CGContextStrokeRect(context, CGRectMake(controlPtsA[i].x, controlPtsA[i].y, 3, 3));
                
                CGContextSetRGBStrokeColor(context, 0, 1, 0, .1);
                CGContextMoveToPoint(context, p[i].x,p[i].y);
                CGContextAddLineToPoint(context, controlPtsA[i].x,controlPtsA[i].y);
                CGContextStrokePath(context);
            }
            
            
        }
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
        
        CGContextSetAllowsAntialiasing(context, TRUE);
        CGContextSetShouldAntialias(context, TRUE);
        
        free(controlPtsA);
        free(controlPtsB);
        
        //Both of these works:
        //1.) Stroke bPath directly
        //CGContextSaveGState(context);
        [bPath stroke];
        //CGContextRestoreGState(context);
        
        /*
         //2. Add bPath to context, then call CGContextStrokePath on context
         CGContextAddPath(context, CGPathCreateCopy(bPath.CGPath));
         CGContextStrokePath(context);
         */
        
        
        time_after_drawing_points = CFAbsoluteTimeGetCurrent();
        
        if(pCount > 5){
            if (time_after_drawing_points > 0){
                CFTimeInterval time_for_drawing = time_after_drawing_points - time_after_processing_points;
                CFTimeInterval time_for_processing = time_after_processing_points - time_start;
                CFTimeInterval time_total = time_after_drawing_points - time_start;
                
                NSLog(@"Total Time elapsed: %g", time_total);
                NSLog(@"Time elapsed for processing: %g (%g%%)", time_for_processing, (time_for_processing/time_total*100));
                NSLog(@"Time elapsed for drawing: %g (%g%%)", time_for_drawing, (time_for_drawing/time_total*100));
            } 
        }
        
        
    } else if (pCount == 2){	
        // just draw a line if only two points
        NSLog(@"just draw a line if only two points");
        CGContextMoveToPoint(context, p[0].x,p[0].y);
        CGContextAddLineToPoint(context, p[1].x,p[1].y);
    }
    
    free(p);
    
    
    //What is this line for? Consider comment away
    //CGContextStrokePath(context);
}

@end
