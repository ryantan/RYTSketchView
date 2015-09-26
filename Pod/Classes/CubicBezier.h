//
//  CubicBezier.h
//  RYTSketchView
//
//  Created by Ryan Tan on 10/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CubicBezier : NSObject {
    
}

+ (CGPoint) normalize:(CGPoint)point to:(float)d;


/* pubic static function drawCurve
 *	Draws a single cubic Bézier curve
 *	@param:
 *		g:Graphics			-Graphics on which to draw the curve
 *		p1:Point			-First point in the curve
 *		p2:Point			-Second point (control point) in the curve
 *		p3:Point			-Third point (control point) in the curve
 *		p4:Point			-Fourth point in the curve
 *	@return:
 */	
static void drawCurve(CGContextRef g, CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4);


/* public static function curveThroughPoints
 *	Draws a smooth curve through a series of points. For a closed curve, make the first and last points the same.
 *	@param:
 *		g:Graphics			-Graphics on which to draw the curve
 *		p:Array				-Array of Point instances
 *		z:Number			-A factor (between 0 and 1) to reduce the size of curves by limiting the distance of control points from anchor points.
 *							 For example, z=.5 limits control points to half the distance of the closer adjacent anchor point.
 *							 I put the option here, but I recommend sticking with .5
 *		angleFactor:Number	-Adjusts the size of curves depending on how acute the angle between points is. Curves are reduced as acuteness
 *							 increases, and this factor controls by how much.
 *							 1 = curves are reduced in direct proportion to acuteness
 *							 0 = curves are not reduced at all based on acuteness
 *							 in between = the reduction is basically a percentage of the full reduction
 *		moveTo:Bollean		-Specifies whether to move to the first point in the curve rather than continuing drawing
 * 							 from wherever drawing left off.
 *	@return:
 */	
+ (void) curveThroughPoints:(NSArray *)points context:(CGContextRef)context z:(float)z angleFactor:(float)angleFactor moveTo:(bool)moveTo showControlPoints:(bool)showControlPoints;
+ (void) curveThroughPoints:(NSArray *)points context:(CGContextRef)context showControlPoints:(_Bool)showControlPoints;

extern float distanceBetweenPoints(CGPoint pointA, CGPoint pointB);
extern float distanceBetweenPointsSquared(CGPoint pointA, CGPoint pointB);
extern float approx_distance( SInt32 dx, SInt32 dy );
extern CGPoint offset(CGPoint p, float x, float y);
extern CGPoint polar(float distance, float angle);

//@property(nonatomic, readwrite) bool showControlPoints;


@end
