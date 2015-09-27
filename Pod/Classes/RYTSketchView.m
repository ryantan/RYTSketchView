//
//  SketchView.m
//  RYTSketchView
//
//  Created by Ryan Tan on 1/9/11.
//  Copyright (c) 2011 Ryan Tan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RYTSketchView.h"
#import "RYTSketchViewUtils.h"
#import "UIColor-Expanded.h"

// Convenience macro to convert color values. 
// TODO: Test if this is faster than using UIColor-Expanded methods
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

const NSUInteger kThreshold = 5;

static UIImage *_clipboardContent = nil;

@interface RYTSketchView () {
    
    NSMutableDictionary *strokes; // strokes in progress, i.e. those where finger has not lifted, so will be mutating.
    NSMutableArray *finishedStrokes; // finished strokes, i.e. those where the finger as lifted, so will not mutate anymore.
    UIColor *_penColor; // the current drawing color
    
    CGImageRef flattenedImage_;
    CGImageRef templateImage;
    CGImageRef strokesImage;
    
    CGFloat _bufferWidth;
    CGFloat _bufferHeight;
    
    UITouch *touchForPan1;
    UITouch *touchForPan2;
    
    CGContextRef strokesContext;
    
    // The eraser radius indicator view
    //UIView *eraserOutline;
    //CALayer *eraserOutlineLayer;
    
    BOOL clearContextOnNextDraw;
    
    NSInteger historyCursor;
    //NSUInteger historyCursorMax;
    NSMutableArray *history;
    
    
    //Marquee related
    CGPoint marqueeStart;
    CGPoint marqueeEnd;
    CGPoint marqueeMoveStart;
    CGPoint marqueeMoveEnd;
    CGRect marqueedRect;
    BOOL marqueeDrawn;
    BOOL marqueeStartedDrawing;
    CGImageRef marqueedImage;
}

- (void)releaseFlattened;
- (void)releaseTemplate;
- (void)releasMarqueedImage;
- (void)updateUndoRedo;

@end


@implementation RYTSketchView

@synthesize delegate;
@synthesize currentTool = _currentTool; //the current tool, pen or eraser
@synthesize penColor = _penColor;
@synthesize penColorIndex = _penColorIndex;
@synthesize lineWidth = _lineWidth;
@synthesize eraserThickness;
@synthesize unfocused;
@synthesize modified;
@synthesize debugOutput;

// Features
@synthesize zoomEnabled;
@synthesize shouldStoreHistory = _shouldStoreHistory;
@synthesize maxHistoryStates; // @TODO: Implement a customer setter to purge history states.
@synthesize joystickEnabled;

// TODO: Find out if we still need this
//CGContextRef CreateBitmapContext(NSUInteger w, NSUInteger h);

//void * globalBitmapData = NULL;

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self initView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame bufferWidth:(CGFloat)w bufferHeight:(CGFloat)h {
    self = [super initWithFrame:frame];
    if (self) {
        [self initViewWithBufferWidth:w bufferHeight:h];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initViewWithBufferWidth:frame.size.width bufferHeight:frame.size.height];
    }
    return self;
}

- (void)initView {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    [self initViewWithBufferWidth:width bufferHeight:height];
}

- (void)initViewWithBufferWidth:(CGFloat)width bufferHeight:(CGFloat)height {
    
    _bufferWidth = width;
    _bufferHeight = height;
    NSLog(@"_bufferWidth: %f, _bufferHeight: %f", _bufferWidth, _bufferHeight);
    
    // Setup layer
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.layer.shouldRasterize = FALSE;
    //self.layer.magnificationFilter = kCAFilterNearest;
    //self.layer.minificationFilter = kCAFilterNearest;
    
    // initialize strokes and finishedStrokes
    strokes = [[NSMutableDictionary alloc] init];
    finishedStrokes = [[NSMutableArray alloc] init];
    
    // Set default pen options
    self.penColorIndex = 1;
    self.eraserThickness = 20;
    self.lineWidth = 2;
    maxHistoryStates = 10;
    
    self.backgroundColor = [UIColor whiteColor];
    
    // DEBUG:
    self.multipleTouchEnabled = TRUE;
    
    // Reset some states
    [self clearSketchInternal];
    
    
    // init the eraser radius indicator view
    // Deprecated
    /*
    eraserOutline = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.eraserThickness, self.eraserThickness)];
    eraserOutline.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor];
    eraserOutline.layer.borderWidth = 1;
    eraserOutline.layer.cornerRadius = self.eraserThickness/2;
    eraserOutline.alpha = 0;
    [self addSubview:eraserOutline];

    eraserOutlineLayer = (CALayer*)[CALayer layer];
    eraserOutlineLayer.frame = CGRectMake(0, 0, self.eraserThickness, self.eraserThickness);
    eraserOutlineLayer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor];
    eraserOutlineLayer.borderWidth = 1;
    eraserOutlineLayer.cornerRadius = self.eraserThickness/2;
    eraserOutlineLayer.hidden = YES;
    [self.layer addSublayer:eraserOutlineLayer];
    */

    
    
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.minimumNumberOfTouches = 2;
    panRecognizer.minimumNumberOfTouches = 2;
    
    //[self addGestureRecognizer:panRecognizer];
    
    [self resetCanvas];
}

- (void)viewWillAppear {
    NSLog(@"SketchView will appear");
    // Prepare view for appearing
    
    [self prepareForSketching];
}

// Was for the deprecated text tool
/*
- (BOOL)canBecomeFirstResponder {
    return YES;
}
*/

- (void)setShouldStoreHistory:(BOOL)shouldStoreHistory {
    
    // If setting is changing from YES to NO, clear current history
    if (_shouldStoreHistory && !shouldStoreHistory){
        [self purgeAllHistory];
    }
    
    _shouldStoreHistory = shouldStoreHistory;
}


// Clears the canvas and marking sketch as modified
- (void)clearSketch {
    self.modified = YES;
    [self clearSketchInternal];
}

- (void)clearSketchInternal {
    NSLog(@"SketchView.clearSketchInternal");
    [strokes removeAllObjects]; // Clear the dictionary of active strokes.
    [finishedStrokes removeAllObjects]; // Clear the array of finished strokes.
    
    [self releaseFlattened];
    [self setNeedsDisplay];
}

- (void)canvasWillReset {
    
}

- (void)penToolSelected {
    //NSLog(@"penToolSelected");
    _currentTool = RYTSketchToolTypePen;
}


- (void)penToolSelectedWithColorIndex:(NSInteger)colorIndex {
    //NSLog(@"penToolSelectedWithColorIndex");
    _currentTool = RYTSketchToolTypePen;
    self.penColorIndex = colorIndex;
}

- (void)penToolSelectedWithColor:(UIColor *)color {
    //NSLog(@"penToolSelectedWithColor");
    _currentTool = RYTSketchToolTypePen;
    self.penColor = color;
}

- (void)eraserToolSelected {
    //NSLog(@"eraserToolSelected");
    [self flatten];
    _currentTool = RYTSketchToolTypeEraser;
}

// Deprecated
- (void)textToolSelected {
    //NSLog(@"textToolSelected");
}

- (void)marqueeToolSelected {
    //NSLog(@"marqueeToolSelected");
    _currentTool = RYTSketchToolTypeMarquee;
    marqueeDrawn = FALSE;
    marqueeStartedDrawing = FALSE;
}







#pragma mark - Touch related

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesBegan in SketchView");
    
    /*
    // Debug: Double check if multipleTouchEnabled is on for view ancestors
    NSLog(@"touchesBegan: multipleTouchEnabled = %@", (self.multipleTouchEnabled?@"YES":@"NO"));
    NSLog(@"touchesBegan: superview.multipleTouchEnabled = %@", (self.superview.multipleTouchEnabled?@"YES":@"NO"));
    NSLog(@"touchesBegan: superview.superview.multipleTouchEnabled = %@", (self.superview.superview.multipleTouchEnabled?@"YES":@"NO"));
    
    UIView *p = self;
    NSString *prefix = @"self";
    while ((p = p.superview)){
        prefix = [prefix stringByAppendingString:@".superview"];
        NSLog(@"touchesBegan: %@.multipleTouchEnabled = %@", prefix, (p.multipleTouchEnabled?@"YES":@"NO"));
    }
    */
    
    self.modified = TRUE;
    if (unfocused){
        return;
    }
    
    //Trying out other touches
    //NSSet *touchesNew = touches; // this gets only the new touches
    //NSSet *touchesAll = [event allTouches]; // this gets all touches
    //NSLog(@"touchesBegan: %d touches (%d new)", touchesAll.count, touchesNew.count);
    //NSLog(@"touchesBegan: all touches (%d)", touchesAll.count);
    
    
    
    // If 2 touches are close (squared dist < 30,000), treat as pan gesture and do not draw as stroke
    // Not using UIGestureRecognizer to have more control in differentiating stray touches while drawing and pan gestures
    UITouch *touchToIgnore1;
    UITouch *touchToIgnore2;
    if ([event allTouches].count == 2){
        //NSArray *touchesTemp = [[event allTouches] allObjects];
        //CGPoint p1 = [[touchesTemp objectAtIndex:0] locationInView:[self.delegate viewForTouch]];
        //CGPoint p2 = [[touchesTemp objectAtIndex:1] locationInView:[self.delegate viewForTouch]];
        
        touchToIgnore1 = [[[event allTouches] allObjects] objectAtIndex:0];
        touchToIgnore2 = [[[event allTouches] allObjects] objectAtIndex:1];
        CGPoint p1 = [touchToIgnore1 locationInView:[self.delegate viewForTouch]];
        CGPoint p2 = [touchToIgnore2 locationInView:[self.delegate viewForTouch]];

        
        CGFloat dist_squared = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
        //NSLog(@"touchesMoved:\n\tdist_squared=%f", dist_squared);
        
        
        if (dist_squared<30000){
            //NSLog(@"p1=%@, p2=%@", NSStringFromCGPoint(p1), NSStringFromCGPoint(p2));
            //touchToIgnore1 = [touchesTemp objectAtIndex:0];
            //touchToIgnore2 = [touchesTemp objectAtIndex:1];
            
            touchForPan1 = touchToIgnore1;
            touchForPan2 = touchToIgnore2;
            
            //treat these 2 touches as pan
            [self.delegate handlePan:p1 and:p2 phase:1];
        }else{
            touchToIgnore1 = nil;
            touchToIgnore2 = nil;
        }
    }
    
    
    
    
    // Find the touch with highest priority (top left touch)
    // Consider other strokes as stray. (Assuming left handed use.)
    // TODO: Add option for right handed use in the future?
    
    //NSString *key_of_highest_priority;
    UITouch *touchOfHighestPriority;
    NSInteger min_x = 0;
    NSInteger curr_x = 0;
    
    for (UITouch *touch in [event allTouches]) {
        
        // Ignore if these touches are part of the pan gesture
        /*
        NSString *touchKey = [self getKeyFromTouch:touch];
        if ([touchKey isEqualToString:keyToIgnore1] || [touchKey isEqualToString:keyToIgnore2]){
            continue;
        }*/
        if (touch == touchToIgnore1 || touch == touchToIgnore2){
            continue;
        }
        
        //NSLog(@"\t%@ at %.1f, %@", [self getKeyFromTouch:touch], [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
        curr_x = [touch locationInView:self].x;
        if ((min_x == 0)||(curr_x < min_x)){
            //key_of_highest_priority = touchKey;
            touchOfHighestPriority = touch;
            min_x = curr_x;
        }
    }
    //NSLog(@"\tkey_of_highest_priority=%@", key_of_highest_priority);

    UITouch *theTouchToProcess;
    
    //NSLog(@"touchesBegan: new touches (%d)", touchesNew.count);
    for (UITouch *touch in touches){
        /*
        NSString *touchKey = [self getKeyFromTouch:touch];
        //TODO: test if this logic saves time
        if (![key_of_highest_priority isEqualToString:touchKey]){
            continue;
        }
        */
        
        if (touch != touchOfHighestPriority){
            continue;
        }
        
        //NSLog(@"\t%@ at %.1f, %@", touchKey, [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
        theTouchToProcess = touch;
    }
    
    if (theTouchToProcess == nil){
        // No touch to process? Continue
        return;
    }
    
    if (_currentTool == RYTSketchToolTypePen || _currentTool == RYTSketchToolTypeEraser){
        // create and configure a new stroke
        RYTStroke *stroke = [[RYTStroke alloc] init];
        [stroke setStrokeColor:_penColor]; // set stroke's stroke color
        [stroke setLineWidth:_lineWidth]; // set stroke's line width
        if  (_currentTool == RYTSketchToolTypeEraser){
            stroke.isErasing = TRUE;
            [stroke setStrokeColor:[UIColor whiteColor]]; // set stroke's stroke color
        }
        
        // add the location of the first touch to the stroke
        [stroke addPoint:[theTouchToProcess locationInView:self]];
        
        //NSString *key_of_highest_priority = [self getKeyFromTouch:touchOfHighestPriority];
        //[strokes setValue:stroke forKey:key_of_highest_priority];
        [self setStroke:stroke forTouch:touchOfHighestPriority];
        
        // Not using touchKeys anymore to skip generating a touch key when I can just use UITouch to identify
        // Would this harm performance?
        //stroke.touchKey = touchKey;
    }else if (_currentTool == RYTSketchToolTypeMarquee){

        if (marqueeDrawn){
            marqueeMoveStart = [theTouchToProcess locationInView:self];
        }else{
            marqueeStartedDrawing = TRUE;
            
            [self flatten];
            //NSLog(@"touchesBegan for marquee tool");
            marqueeStart = [theTouchToProcess locationInView:self];
            marqueeEnd = marqueeStart;
            //NSLog(@"\tmarqueeStart=%@", NSStringFromCGPoint(marqueeStart));
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesMoved in sketchView");
    
    if (unfocused){
        return;
    }
    
    //NSSet *touchesNew = touches; // get only the new touches
    NSSet *touchesAll = [event allTouches]; // get all touches
    //touchesAll = [event touchesForView:self]; // get all touches for this view
    //NSLog(@"\ntouchesMoved: %d touches (%d new)", touchesAll.count, touchesNew.count);
    //NSLog(@"touchesMoved: all touches (%d)", touchesAll.count);
    
    // Check for pan gesture if touches == 2;
    if (touchesAll.count == 2){
        NSArray *touchesTemp = [touchesAll allObjects];
        CGPoint p1 = [[touchesTemp objectAtIndex:0] locationInView:[self.delegate viewForTouch]];
        CGPoint p2 = [[touchesTemp objectAtIndex:1] locationInView:[self.delegate viewForTouch]];
        
        /*
        NSString *k1 = [self getKeyFromTouch:[touchesTemp objectAtIndex:0]];
        NSString *k2 = [self getKeyFromTouch:[touchesTemp objectAtIndex:1]];
        
        if (([k1 isEqualToString:keyForPanTouch1] && [k2 isEqualToString:keyForPanTouch2])||([k2 isEqualToString:keyForPanTouch1] && [k1 isEqualToString:keyForPanTouch2])){
        */
        
        UITouch *t1 = [touchesTemp objectAtIndex:0];
        UITouch *t2 = [touchesTemp objectAtIndex:1];
        
        if ((t1 == touchForPan1 && t2 == touchForPan2)||(t2 == touchForPan1 && t1 == touchForPan2)){
            
            //These are the touches for the pan gesture
            
            CGFloat dist_squared = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
            //NSLog(@"touchesMoved:\n\tdist_squared=%f", dist_squared);
            
            if (dist_squared<90000){
                //NSLog(@"p1=%@, p2=%@", NSStringFromCGPoint(p1), NSStringFromCGPoint(p2));
                //treat as pan
                [self.delegate handlePan:p1 and:p2 phase:2];
            }
        }else{
            //ignore
        }
        return;
    }
    
    
    
    
    
    // Find the touch with highest priority (top left touch)
    // Consider other strokes as stray. (Assuming left handed use.)
    // TODO: Add option for right handed use in the future?
    
    //NSString *key_of_highest_priority;
    UITouch *touchOfHighestPriority;
    NSInteger min_x = 0;
    NSInteger curr_x = 0;
    
    for (UITouch *touch in touchesAll) {
        
        // If this touch is part of pan, ignore
        
        /*NSString *touchKey = [self getKeyFromTouch:touch];
        if ([touchKey isEqualToString:keyForPanTouch1] || [touchKey isEqualToString:keyForPanTouch2]){continue;}*/
        
        if (touch == touchForPan1 || touch == touchForPan2){
            continue;
        }
        
        //NSLog(@"\t%@ at %.1f, %@", [self getKeyFromTouch:touch], [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
        curr_x = [touch locationInView:self].x;
        if ((min_x == 0)||(curr_x < min_x)){
            //key_of_highest_priority = touchKey;
            touchOfHighestPriority = touch;
            min_x = curr_x;
        }
    }
    //NSLog(@"\tkey_of_highest_priority=%@", key_of_highest_priority);

    
    //Only handle new touches here
    //NSLog(@"touchesMoved: new touches (%d)", touchesNew.count);
    for (UITouch *touch in touches) {
        
        //NSString *touchKey = [self getKeyFromTouch:touch];
        //NSLog(@"\ttouchesMoved: %@ at %.1f, %@", touchKey, [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
        
        //NSLog(@"touchesMoved check current tool");
        if (_currentTool == RYTSketchToolTypePen || _currentTool == RYTSketchToolTypeEraser){
            
            //NSLog(@"touchesMoved while in pen/eraser tool");
            
            RYTStroke *stroke = [self getStrokeForTouch:touch];
            
            if (stroke == nil){
                //NSLog(@"touchesMoved: Got a new touchmove belonging to a stroke that was discarded, %@", touchKey);
                continue;
            }
            
            //if (![key_of_highest_priority isEqualToString:touchKey]){
            if (touch != touchOfHighestPriority){
                //NSLog(@"\t%@ at (%.1f,%.1f), %@", touchKey, [touch locationInView:self].x, [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
                //NSLog(@"\tignoring %@", touchKey);
                stroke.ignored = TRUE;
                CGRect rectToRedraw = [stroke getRect];
                [self setNeedsDisplayInRect:rectToRedraw];
                continue;
            }
            //NSLog(@"\t%@ at %.1f, %@ (highest)", touchKey, [touch locationInView:self].y, UITouchPhaseToString(touch.phase));
            
            //NSLog(@"touchesMoved: Now processing the highest touch %@", touchKey);
            
            // get the current and previous touch locations
            CGPoint current = [touch locationInView:self];
            CGPoint previous = [touch previousLocationInView:self];
            [stroke addPoint:current]; // add the new point to the stroke
            
            // Determine the rect that should be redrawn (dirty rect)
            CGPoint lower, higher;
            lower.x = (previous.x > current.x ? current.x : previous.x);
            lower.y = (previous.y > current.y ? current.y : previous.y);
            higher.x = (previous.x < current.x ? current.x : previous.x);
            higher.y = (previous.y < current.y ? current.y : previous.y);
            
            // Give some buffer (TODO: might not be needed if testing shows lineWidth is accurate)
            lower.x -= 10;
            lower.y -= 10;
            higher.x += 10;
            higher.y += 10;
            
            if  (_currentTool == RYTSketchToolTypeEraser){
                // Deprecated
                //if is eraser, move the eraser outline view
                //eraserOutline.center = current;
                //eraserOutline.alpha = 1.0;
                //eraserOutlineLayer.position = current;
                //eraserOutlineLayer.hidden = NO;
                
                //if is eraser, increase the area that needs to be redrawn to compensate for stroke width
                lower.x -= 20;
                lower.y -= 20;
                higher.x += 20;
                higher.y += 20;
            }
            
            // redraw the screen in the required region
            [self setNeedsDisplayInRect:CGRectMake(lower.x - _lineWidth,
                                                   lower.y - _lineWidth, higher.x - lower.x + _lineWidth * 2,
                                                   higher.y - lower.y + _lineWidth * 2)];
            
        }else if (_currentTool == RYTSketchToolTypeMarquee){
            
            CGPoint current = [touch locationInView:self];
            
            //NSLog(@"touchesMoved while in marquee tool");
            
            
            //if (![key_of_highest_priority isEqualToString:touchKey]){continue;}
            
            if (touch != touchOfHighestPriority){
                continue;
            }
            
            if (marqueeDrawn){
                marqueeMoveEnd = current;
                [self setNeedsDisplay];
            }else{
                marqueeEnd = current;
                //NSLog(@"\tmarqueeEnd=%@", NSStringFromCGPoint(marqueeEnd));
                //[self setNeedsDisplayInRect:[self getRectFromMarqueePoints]];
                [self setNeedsDisplay];
            }
        }
        

        
        
    }
    //Debug: refresh the whole view for debug
    //TODO: Consider how to optimize this
    //[self setNeedsDisplayInRect:self.frame];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesEnded in strokesView");
    
    if (unfocused){
		[[NSNotificationCenter defaultCenter] postNotificationName:@"backToSketch" object:self];
        return;
    }
    
    //NSSet *touchesNew = touches; // get only the new touches
    ////NSSet *touchesAll = [event allTouches]; // get all touches
    ////touchesAll = [event touchesForView:self]; // get all touches for this view
    //NSLog(@"touchesEnded: %d touches (%d new)", touchesAll.count, touchesNew.count);
    
    
    if (touches.count == 1){
        if ([[touches anyObject] tapCount] == 2){
            UITouch *touch = [touches anyObject];
            CGPoint current = [touch locationInView:self];
            CGPoint prev = [touch previousLocationInView:self];
            if (current.x == prev.x && current.y == prev.y){
                //NSString *touchKey = [self getKeyFromTouch:touch];
                //[strokes removeObjectForKey:touchKey]; // remove from strokes
                [self removeStrokeByTouch:touch]; // remove from strokes
                //handle zoom in
                [self.delegate zoomInToPoint:current];
                return;
            }
        }
    }
    
    
    // loop through the touches
    for (UITouch *touch in touches) {

        //NSString *touchKey = [self getKeyFromTouch:touch];
        
        
        if (_currentTool == RYTSketchToolTypePen || _currentTool == RYTSketchToolTypeEraser){
            
            // retrieve the stroke for this touch using the key
            
            //Stroke *stroke = [strokes valueForKey:touchKey];
            RYTStroke *stroke = [self getStrokeForTouch:touch];
            
            if (stroke == nil){
                //NSLog(@"touchesEnded: Got a new touchEnd belonging to a stroke that was discarded");
                continue;
            }
            
            if (stroke.ignored){
                NSLog(@"touchesEnded: ignoring a stroke");
                [self removeStrokeByTouch:touch]; // remove from strokes
                continue;
            }

            if (touch.tapCount == 1){
                //NSLog(@"touch.tapCount = %d", touch.tapCount);
                CGPoint current = [touch locationInView:self];
                current.x += 2.0;
                current.y += 2.0;
                CGPoint previous = [touch previousLocationInView:self];
                [stroke addPoint:current]; // add the new point to the stroke 
                
                // Create two points: one with the smaller x and y values and one
                // with the larger. This is used to determine exactly where on the
                // screen needs to be redrawn.
                CGPoint lower, higher;
                lower.x = (previous.x > current.x ? current.x : previous.x);
                lower.y = (previous.y > current.y ? current.y : previous.y);
                higher.x = (previous.x < current.x ? current.x : previous.x);
                higher.y = (previous.y < current.y ? current.y : previous.y);
                
                // Only redraw the screen in the required region.
                //[self setNeedsDisplayInRect:CGRectMake(lower.x - lineWidth,
                //                                       lower.y - lineWidth, 
                //                                       higher.x - lower.x + lineWidth * 2,
                //                                       higher.y - lower.y + lineWidth * 2)];
                
                // Redraw the whole view.
                //TODO: Consider how to optimise this
                [self setNeedsDisplayInRect:self.frame];
            }
            
            // remove the stroke from the dictionary and place it in an array
            // of finished strokes
            [finishedStrokes addObject:stroke]; // add to finishedStrokes
            
            [self removeStrokeByTouch:touch]; // remove from strokes
            
            //NSLog(@"finishedStrokes:%d, strokes:%d", finishedStrokes.count, strokes.count);
            
            /*
            if([finishedStrokes count] > kThreshold)  { 
                [self flatten];
                NSLog(@"after flatten: finishedStrokes:%d, strokes:%d", finishedStrokes.count, strokes.count);
            }else{
             
            }
            */
            
            //flatten anyways in order to save history
            if (_shouldStoreHistory){
                [self flatten];
                [self saveHistory];
            }
            
        }else if (_currentTool == RYTSketchToolTypeMarquee){
            
            CGPoint current = [touch locationInView:self];
            
            if (marqueeDrawn){
                //marqueeMoveEnd = current;
                [self endMarquee];
            }else{
                marqueeEnd = current;
                [self cutOutMarquee];
                //NSLog(@"\tmarqueeEnd=%@", NSStringFromCGPoint(marqueeEnd));
            }
        }
    } // end for
    
    
    if  (_currentTool == RYTSketchToolTypeEraser){
        //if is eraser, hide  the outline
        //eraserOutline.alpha = 0.0;
        //eraserOutlineLayer.hidden = YES;
        
        
        //remember to flatten if was in eraser mode
        [self flatten];
    }

} // end method touchesEnded:withEvent:

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    //NSSet *touchesNew = touches; // get only the new touches
    //NSSet *touchesAll = [event allTouches]; // get all touches
    //NSLog(@"touchesCancelled: %d touches (%d new)", touchesAll.count, touchesNew.count);
    
    
    
    for (UITouch *touch in touches) {
        
        // retrieve the stroke for this touch using the key
        //NSString *touchKey = [self getKeyFromTouch:touch];
        //RYTStroke *stroke = [strokes valueForKey:touchKey];
        RYTStroke *stroke = [self getStrokeForTouch:touch];
        
        if (stroke == nil){
            //NSLog(@"touchesCancelled: Got a touchesCancelled belonging to a stroke that was discarded %@", touchKey);
            NSLog(@"touchesCancelled: Got a touchesCancelled belonging to a stroke that was discarded");
            continue;
        }
        
        stroke.ignored = TRUE;
        CGRect rectToRedraw = [stroke getRect];
        [self setNeedsDisplayInRect:rectToRedraw];
        
        NSLog(@"touchesCancelled: ignoring a stroke");
        //[strokes removeObjectForKey:touchKey]; // remove from strokes
        [self removeStrokeByTouch:touch];
        
    }
    
    
}

- (NSString*)getKeyFromTouch:(UITouch*)touch{
    // the key for each touch is the value of the pointer
    NSValue *touchValue = [NSValue valueWithPointer:(__bridge const void *)touch];
    NSString *key = [NSString stringWithFormat:@"%@", touchValue];
    return key;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer{
    NSLog(@"handlePan:");
    CGPoint translation = [recognizer translationInView:self];
    
    /*
    if (recognizer.numberOfTouches == 2){
        CGPoint p1 = [recognizer locationOfTouch:0 inView:self];
        CGPoint p2 = [recognizer locationOfTouch:1 inView:self];
        
        CGFloat dist = sqrt(((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y)));
        //NSLog(@"SketchView.handlePan:, dist=%f", dist);
    }
    */
    
    if (self.delegate){
        [self.delegate handlePan:recognizer translation:translation];
    }else{
        NSLog(@"SketchView.handlePan:, no delegate!");
    }
    
}


#pragma mark - Strokes management

- (RYTStroke *)getStrokeForTouch:(UITouch *)touch{
    NSString *touchKey = [self getKeyFromTouch:touch];
    return (RYTStroke*)[strokes valueForKey:touchKey];
}

-(void)setStroke:(RYTStroke *)stroke forTouch:(UITouch *)touch{
    NSString *touchKey = [self getKeyFromTouch:touch];
    [strokes setValue:stroke forKey:touchKey];
}

-(void)removeStrokeByTouch:(UITouch *)touch{
    NSString *touchKey = [self getKeyFromTouch:touch];
    [strokes removeObjectForKey:touchKey];
}



#pragma mark - Graphics Related

- (void)resetCanvas {
    [self canvasWillReset];
    NSLog(@"SketchView.resetCanvas");
    [self clearSketchInternal];
    
    [self releaseTemplate];
    
    if (strokesContext != NULL){
        CFRelease(strokesContext);
    }
    
    // Done in prepareForSketching
    //[self createStrokesContext];
    
    [self purgeAllHistory];
}

// Called primarily from viewWillAppear.
- (void)prepareForSketching {
    NSLog(@"SketchView.prepareForSketching");
    
    // Ensure we have a valid bitmap context for strokes
    [self ensureStrokesContext];
    
    // You can read this setting from NSUserDefaults too, but converted it
    // into a property.
    //shouldStoreHistory = [[NSUserDefaults standardUserDefaults] boolForKey:kDK_PREF_USEHISTORY];
    //[self purgeAllHistory];
    
    // Initialize history
    [self initHistory];
    [self flatten];
    [self saveHistory];
    
}

- (void)drawRect:(CGRect)rect {
    
    CGRect fullRect = CGRectMake(0, 0, _bufferWidth, _bufferHeight);
    
    //TODO: test if this speeds up drawing?
    //fullRect = rect;
    
    // get the current graphics context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Debugging
    //unsigned long contextWidth = CGBitmapContextGetWidth(context);
    //unsigned long contextHeight = CGBitmapContextGetHeight(context);
    //NSLog(@"contextWidth: %lu, contextHeight: %lu", contextWidth, contextHeight);
    
    //Automatically cleared by UIKit
    //CGContextClearRect(context, fullRect);
    
    // Don't fill since we want a transparent image.
    //CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    //CGContextFillRect(context, fullRect);
    
    //CGContextSetShouldAntialias(context, FALSE);
    
    // For debug
    //UIImage *contextPreview = [RYTSketchViewUtils getUIImageFromCGContext:context]; // For quick view
    //[RYTSketchViewUtils writeCGContext:context toFileName:@"current_context.png"];
    
    // Draw template layer in case parts of it got erased.
    // TODO: Fill template once when setting template, instead of filling
    // every drawRect.
    if(templateImage){
        CGContextDrawImage(context, fullRect, templateImage);
    }
    //contextPreview = [RYTSketchViewUtils getUIImageFromCGContext:context]; // For debug
    //[RYTSketchViewUtils writeCGContext:context toFileName:@"current_context_template.png"];
    
    
    // Use another draw method if tool is eraser.
//    if (_currentTool == RYTSketchToolTypeEraser){
//        [self drawRectWithExtraContext:rect inContext:context];
//    }else{
//        [self drawRectWithSameContext:rect inContext:context];
//    }

    [self drawRectWithExtraContext:rect inContext:context];
    
    //Debug: Write out context to test
    //[RYTSketchViewUtils writeCGContext:context toFileName:@"context_end.png"];
    
    
    
    if (_currentTool == RYTSketchToolTypeMarquee){
        if (marqueeDrawn){
            if(marqueedImage){
                CGRect destRect = CGRectMake(marqueedRect.origin.x + (marqueeMoveEnd.x-marqueeMoveStart.x), marqueedRect.origin.y + (marqueeMoveEnd.y-marqueeMoveStart.y), marqueedRect.size.width, marqueedRect.size.height);
                NSLog(@"drawRectWithSameContext, marquee destRect = %@", NSStringFromCGRect(destRect));
                CGContextDrawImage(context, destRect, marqueedImage);
            }
            [self drawMarqueeSourceRectWithAlpha:0.3 inContext:context];
        }else{
            if (marqueeStartedDrawing){
                [self drawMarqueeSourceRectWithAlpha:0.6 inContext:context];
            }
        }
    }
}

// Draw method for "normal" tools like pen.
// Deprecated. All tools use this now so that we don't draw strokes that are
// too smooth when zoomed in. i.e. always back our drawing with an off-screen
// context.
//- (void)drawRectWithSameContext:(CGRect)rect inContext:(CGContextRef)context {
//    
//    CGRect fullRect = CGRectMake(0, 0, _bufferWidth, _bufferHeight);
//    
//    if(flattenedImage_){
//        //unsigned long flattenedImageWidth = CGImageGetWidth(flattenedImage_);
//        //unsigned long flattenedImageHeight = CGImageGetHeight(flattenedImage_);
//        //NSLog(@"flattenedImageWidth: %lu, flattenedImageHeight: %lu", flattenedImageWidth, flattenedImageHeight);
//        CGContextDrawImage(context, fullRect, flattenedImage_);
//    }
//    
//    
//    [self ensureStrokesContext];
//    CGContextClearRect(strokesContext, fullRect);
//    
//    // Draw all the finished strokes.
//    //NSLog(@"drawRectWithSameContext, finishedStrokes.count = %lu", (unsigned long)finishedStrokes.count);
//    for (Stroke *stroke in finishedStrokes){
//        [self drawStroke:stroke inContext:strokesContext];
//    }
//    
//    // Draw all the currently active strokes.
//    //NSLog(@"drawRectWithSameContext, strokes.count = %lu", (unsigned long)strokes.count);
//    for (NSString *key in strokes){
//        Stroke *stroke = [strokes valueForKey:key];
//        [self drawStroke:stroke inContext:strokesContext];
//    }
//    
//    CGImageRelease(strokesImage);
//    strokesImage = CGBitmapContextCreateImage(strokesContext);
//    if(strokesImage){
//        CGContextDrawImage(context, fullRect, strokesImage);
//    }
//    
//}

// Draw method that draw new strokes on a separate buffer before drawing on
// current context.
- (void)drawRectWithExtraContext:(CGRect)rect inContext:(CGContextRef)context {
    
    // Define rect
    CGRect fullRect = CGRectMake(0, 0, _bufferWidth, _bufferHeight);
    
    // Make sure we have our context.
    // TODO: Is there any chance for this to be released prematurely?
    [self ensureStrokesContext];
    CGContextClearRect(strokesContext, fullRect);
    
    // Draw flattened image to strokesContext so that our erasing strokes can
    // erase existing strokes.
    if(flattenedImage_){
        CGContextDrawImage(strokesContext, fullRect, flattenedImage_);
    }
    // For debug.
    //UIImage *strokesContextPreview = [RYTSketchViewUtils getUIImageFromCGContext:strokesContext]; // For quick view.
    //[RYTSketchViewUtils writeCGContext:strokesContext toFileName:@"eraser_strokesContext.png"];
    
    // Draw all the finished strokes that are not yet in flattenedImage
    // into strokesContext.
    //NSLog(@"drawRectWithExtraContext, finishedStrokes.count = %lu", (unsigned long)finishedStrokes.count);
    for (RYTStroke *stroke in finishedStrokes){
        [self drawStroke:stroke inContext:strokesContext];
    }
    
    // Draw all the currently active strokes into strokesContext.
    //NSLog(@"drawRectWithExtraContext, strokes.count = %lu", (unsigned long)strokes.count);
    for (NSString *key in strokes){
        RYTStroke *stroke = [strokes valueForKey:key];
        [self drawStroke:stroke inContext:strokesContext];
    }
    
    // For debug.
    //UIImage *strokesContextPreview = [RYTSketchViewUtils getUIImageFromCGContext:strokesContext]; // For quick view.
    //[RYTSketchViewUtils writeCGContext:strokesContext toFileName:@"eraser_strokesContext_strokes.png"];

    // Draw our strokes.
    CGImageRelease(strokesImage);
    strokesImage = CGBitmapContextCreateImage(strokesContext);
    if(strokesImage){        
        CGContextDrawImage(context, fullRect, strokesImage);
    }
    
    // For debug.
    //contextPreview = [RYTSketchViewUtils getUIImageFromCGContext:context]; // For quick view.
    //[RYTSketchViewUtils writeCGContext:context toFileName:@"eraser_current_context_template_strokes.png"];
    
}

// Draws the given stroke into the given context.
- (void)drawStroke:(RYTStroke *)stroke inContext:(CGContextRef)context {
    
    if (stroke.ignored) return;
    
    //NSLog(@"drawStroke in strokesView, isErasing=%@", (stroke.isErasing?@"Yes":@"No"));
    
    // Different context settings for eraser v.s. pen.
    if (stroke.isErasing){
        
        // Color does not matter here, because we are using kCGBlendModeClear.
        CGColorRef colorRef = [UIColor whiteColor].CGColor;
        //CGColorRef colorRef = [UIColor clearColor].CGColor;
        CGContextSetStrokeColorWithColor(context, colorRef);
        
        //Set the blend mode so that whatever is drawn completely replaces that in the context
        //CGContextSetBlendMode(context, kCGBlendModeCopy);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        
        // Set line width to constant value
        CGContextSetLineWidth(context, self.eraserThickness);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        //CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        
    }else{
        
        // Set the drawing color to the stroke's color
        CGColorRef colorRef = stroke.strokeColor.CGColor;
        CGContextSetStrokeColorWithColor(context, colorRef);
        
        //Set the blend mode so that whatever is drawn adds to that in the context
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        //CGContextSetBlendMode(context, kCGBlendModeMultiply);
        
        // set the line width to the stroke's line width
        CGContextSetLineWidth(context, stroke.lineWidth);
        CGContextSetLineCap(context, kCGLineCapRound);
        //CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    }
    
    NSMutableArray *points = [stroke points]; // get points from stroke
                                              //NSLog(@"[points count]=%d", [points count]);
    
    // retrieve the NSValue object and store the value in firstPoint
    CGPoint firstPoint; // declare a CGPoint
    [[points objectAtIndex:0] getValue:&firstPoint];
    
    // Move to the point
    CGContextMoveToPoint(context, firstPoint.x, firstPoint.y);
    
    CGPoint point;
    // Draw a line from each point to the next in order
    for (int i = 1; i < points.count; i++) {
        
        [points[i] getValue:&point]; // store the value in point
        
        // Draw a line to the new point
        CGContextAddLineToPoint(context, point.x, point.y);
    }
    
    // Materialize the path.
    CGContextStrokePath(context);
    
    // If this is an erasing stroke, we had set blend mode to clear at the
    // start. We should set it back to normal, just in case other drawing
    // functions forgot to set it back to normal before drawing.
    if (stroke.isErasing){
        //set the blendmode back to normal
        CGContextSetBlendMode(context, kCGBlendModeNormal);
    }
    
}

// Draw finished strokes into the flattened image.
- (void)flatten {
    NSLog(@"RYTSketchView flatten");
    
    //CGRect bounds = self.bounds;
    CGRect bounds = CGRectMake(0, 0, _bufferWidth, _bufferHeight);
    
    CGContextRef context = CreateBitmapContext(_bufferWidth, _bufferHeight);
    
    if (context == nil){
        //TODO: Handle this better?
        NSLog(@"Could not create bitmapContent, failing silenty");
        //[RYTSketchViewUtils log:@"Could not create bitmapContent, failing silenty" inSection:@"SketchView.flatten"];
        return;
    }
    
    
    //NSLog(@"flattenedImage_ dimensions: %lu x %lu", CGImageGetWidth(flattenedImage_), CGImageGetHeight(flattenedImage_));
    
    CGContextClearRect(context, bounds);
    //CGContextClearRect(context, CGRectMake(0, 0, width/2, height/2));
    

    //Debug: Write out current context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"flatten-1.png" isRelativeToDocument:TRUE];
    
    //Debug: Write out flattenedImage_ to test
    //[RYTSketchViewUtils writeCGImage:flattenedImage_ toFileName:@"flatten-2.png"];
    
    if(flattenedImage_) {
        //unsigned long flattenedImageWidth = CGImageGetWidth(flattenedImage_);
        //unsigned long flattenedImageHeight = CGImageGetHeight(flattenedImage_);
        CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(flattenedImage_), CGImageGetHeight(flattenedImage_)), flattenedImage_);
    }
    
    //Debug: Write out current context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toFileName:@"flatten-3.png"];
    
    // Draw strokes that have not yet been flattened into flattenedImage_.
    for (RYTStroke *stroke in finishedStrokes) {
        [self drawStroke:stroke inContext:context];
    }
    
    //Debug: Write out current context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toFileName:@"flatten-4.png"];

    
    [self releaseFlattened];
    flattenedImage_ = CGBitmapContextCreateImage(context);
    //if (flattenedImage_){
    //    NSLog(@"flattenedImage_ is not NULL");
    //}
    //UIImage *previewContextImage = [RYTSketchViewUtils getUIImageFromCGContext:context];
    //UIImage *previewFlattenedImage = [UIImage imageWithCGImage:flattenedImage_];
    CGContextRelease(context);
    
    [finishedStrokes removeAllObjects];
}

- (UIImage *)getUIImage{
    [self flatten];
    UIImage *sketch = [UIImage imageWithCGImage:flattenedImage_];
    return sketch;
}

- (UIImage *)getThumbnail{
    [self flatten];
    
    NSUInteger w = CGRectGetWidth(self.bounds)/3;
    NSUInteger h = CGRectGetHeight(self.bounds)/3;
    
    
    CGContextRef context = CreateBitmapContext(w, h);
    CGContextClearRect(context, CGRectMake(0, 0, w, h));
    
    // Flip vertically to compensate for the different coordinate systems
    BOOL flipY = TRUE;
    
    CGAffineTransform flipVertical; // = CGAffineTransformMake(0, 0, 0, 0, 0, 0);
    if(flipY){
        flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, h);
    }else{
        flipVertical = CGAffineTransformMake(-1, 0, 0, 1, w, 0);
    }
    CGContextConcatCTM(context, flipVertical);
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), templateImage);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), flattenedImage_);
    CGImageRef thumbnailImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImage];
    CGImageRelease(thumbnailImage);
    
    return thumbnail;
}

- (void) initWithUIImage:(UIImage*)sketch{
    NSLog(@"initWithUIImage");
    
    self.modified = FALSE;
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    // As of Xcode 5, the debugger allow us to view this image via quick view.
    //Debug: Write out current context to test
    //[RYTSketchViewUtils writeImage:sketch toPath:@"test" withFileName:@"test1.png" isRelativeToDocument:TRUE];
    
    CGImageRef sourceImageRef = [sketch CGImage];
    
    CGContextRef context = CreateBitmapContext(width, height);
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    // As of Xcode 5, the debugger allow us to view this image via quick view.
    //Debug: Write out current context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"test2.png" isRelativeToDocument:TRUE];
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), sourceImageRef);
    
    [self releaseFlattened];
    flattenedImage_ = CGBitmapContextCreateImage(context);
    //Debug: Write out current image to test
    //[RYTSketchViewUtils writeCGImage:flattenedImage_ toPath:@"test" withFileName:@"test3.png" isRelativeToDocument:TRUE];
    
    CGContextRelease(context);
    
    //Debug: Write out current image to test
    //[RYTSketchViewUtils writeCGImage:imgRef toPath:@"test" withFileName:@"test-final.png" isRelativeToDocument:TRUE];

    
    // Initialize history
    [self initHistory];
    [self flatten];
    [self saveHistory];
    
    
    [self setNeedsDisplay];
}

- (void)setTemplate:(UIImage*)template{
    NSLog(@"setTemplate");
    
    self.modified = FALSE;
    
    CGImageRef sourceImageRef = [template CGImage];
    // Write out image to test
    //[RYTSketchViewUtils writeCGImage:sourceImageRef toPath:@"test" withFileName:@"setTemplate-template.png" isRelativeToDocument:TRUE];
    
    CGRect bounds = self.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGRect templateRect = CGRectMake(0, 0, width, height);
    
    //NSLog(@"self.bounds = (%f x %f), template.size = (%f x %f)",width, height, template.size.width, template.size.height);
    
    CGContextRef context = CreateBitmapContext(width, height);
    
    // Write out image to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"setTemplate-1.png" isRelativeToDocument:TRUE];
    
    CGContextClearRect(context, templateRect);
    
    // Write out image to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"setTemplate-2.png" isRelativeToDocument:TRUE];

    // Flip the template image (in CG world the y axis is flipped).
    // NOTE: Use bounds.size.height instead of template.size.width. because
    // bound's height is scaled to the right size, template is the
    // original height.
    CGAffineTransform newTransform;
    
    // Define matrix using CGAffineTransformMakeScale.
    newTransform = CGAffineTransformMakeScale(1, -1);
    newTransform = CGAffineTransformTranslate(newTransform, 0, -height);
    
    // Or you can define the matrix manually.
    //BOOL flipY = TRUE;
    //if(flipY){
    //    newTransform = CGAffineTransformMake(1, 0, 0, -1, 0, template.size.height);
    //}else{
    //    newTransform = CGAffineTransformMake(-1, 0, 0, 1, template.size.width, 0);
    //}
    
    CGContextConcatCTM(context, newTransform);
    
    CGContextDrawImage(context, templateRect, sourceImageRef);
    
    [self releaseTemplate];
    templateImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    // Write out image to test
    //[RYTSketchViewUtils writeCGImage:imgRef toPath:@"test" withFileName:@"setTemplate-final.png" isRelativeToDocument:TRUE];

    [self setNeedsDisplay];
}














- (void)createStrokesContext {
    NSLog(@"Size of new BitmapContext: %f x %f", _bufferWidth, _bufferHeight);
    strokesContext = CreateBitmapContext(_bufferWidth, _bufferHeight);
    
    // Test antialias
    //CGContextSetShouldAntialias(strokesContext, FALSE);
}

- (void)ensureStrokesContext {
    //NSLog(@"ensureStrokesContext");
    if (strokesContext != NULL){
        // We're fine!
        //NSLog(@"Context is fine");
    }else{
        // Where did it go??
        [self createStrokesContext];
    }
}






// Private methods

// CG objects are not released by ARC, so clean them up
- (void)releaseFlattened {
    //NSLog(@"releaseFlattened");
    if (flattenedImage_ != NULL){
        //CFRelease(flattenedImage_);
        CGImageRelease(flattenedImage_);
    }
    flattenedImage_ = NULL;
}

- (void)releaseTemplate {
    //NSLog(@"releaseTemplate");
    if (templateImage != NULL){
        //CFRelease(templateImage);
        CGImageRelease(templateImage);
    }
    templateImage = NULL;
}

- (void)releasMarqueedImage {
    //NSLog(@"releasMarqueedImage");
    if (marqueedImage != NULL){
        //CFRelease(marqueedImage);
        CGImageRelease(marqueedImage);
    }
    marqueedImage = NULL;
}





















#pragma mark - Pen options

- (void)setPenThickness:(NSInteger)thickness{

    switch (thickness) {
        case 1:
            _lineWidth = 2;
            break;
        case 2:
            _lineWidth = 4;
            break;
        case 3:
            _lineWidth = 6;
            break;
            
        default:
            _lineWidth = 2;
            break;
    }
}

- (NSInteger)getPenThickness{
    switch ([[NSNumber numberWithFloat:_lineWidth] integerValue]) {
        case 2:
            return 1;
            break;
        case 4:
            return 2;
            break;
        case 6:
            return 3;
            break;
            
        default:
            return 1;
            break;
    }
}

- (NSInteger)penColorIndex {
    return _penColorIndex;
}

- (NSInteger)getPenColorIndexFromColor:(UIColor*)color {
    //CGFloat r, g, b, a;
    //[color getRed:&r green:&g blue:&b alpha:&a];
    
    NSString *h = [[color hexStringFromColor] uppercaseString];
    //NSLog(@"h=%@", h);
    
    if ([h isEqualToString:@"030303"]){
        return 1;
    }else if ([h isEqualToString:@"599ECF"]){
        return 2;
    }else if ([h isEqualToString:@"264773"]){
        return 3;
    }else if ([h isEqualToString:@"9EBC2D"]){
        return 4;
    }else if ([h isEqualToString:@"D11449"]){
        return 5;
    }else if ([h isEqualToString:@"920E33"]){
        return 6;
    }else{
       return 0;
    }
}

- (void)setPenColorIndex:(NSInteger)penColorIndex {
    
    _penColorIndex = penColorIndex;
    
    switch (_penColorIndex) {
        case 1:
            _penColor = [UIColor colorWithRGBHex:0x030303];
            break;
        case 2:
            _penColor = [UIColor colorWithRGBHex:0x599ecf];
            break;
        case 3:
            _penColor = [UIColor colorWithRGBHex:0x264773];
            break;
        case 4:
            _penColor = [UIColor colorWithRGBHex:0x9ebc2d];
            break;
        case 5:
            _penColor = [UIColor colorWithRGBHex:0xd11449];
            break;
        case 6:
            _penColor = [UIColor colorWithRGBHex:0x920e33];
            break;
            
        default:
            _penColorIndex = 0;
            _penColor = [UIColor colorWithRGBHex:0x030303];
            break;
    }
}

- (UIColor*)penColor{
    return _penColor;
}

- (void)setPenColor:(UIColor*)color {
    _penColor = color;
    self.penColorIndex = [self getPenColorIndexFromColor:color];
}






















#pragma mark - History Undo & Redo

- (void)initHistory {
    NSLog(@"SketchView.initHistory");
    if (history){
        [self purgeAllHistory];
    }
    history = [NSMutableArray arrayWithCapacity:10];
}

- (void)saveHistory{
    //NSLog(@"SketchView.saveHistory");
    
    // TODO: Ensure history is initialized?
    if (!history){
        NSLog(@"history is false");
    }
    if (history == nil){
        NSLog(@"history is nil");
    }
    
    [self purgeHistoryAfterCursor];
    
    CGImageRef newHistoryImage = CGImageCreateCopy(flattenedImage_);
    //UIImage *previewHistoryImage = [UIImage imageWithCGImage:newHistoryImage];
    //if (newHistoryImage){
    //    NSLog(@"newHistoryImage is not NULL");
    //}
    [history addObject:(__bridge id)newHistoryImage];
    CGImageRelease(newHistoryImage);
    
    // Remove history states more than maxHistoryStates to conserve memory
    if (history.count > maxHistoryStates){
        
        // Removing items from the array does not properly release the CGImages, so
        // manually releasing them below.
        //[history removeObjectsInRange:NSMakeRange(0, (history.count-6))];        
        
        CGImageRef imageInHistory;
        for (int i=0; i<history.count - maxHistoryStates; i++){
            imageInHistory = (CGImageRef)CFBridgingRetain([history objectAtIndex:i]);
            CGImageRelease(imageInHistory);
            [history removeObjectAtIndex:i];
            imageInHistory = nil;
        }
    }
    
    historyCursor = history.count - 1;
    [self updateUndoRedo];
}

// Purge history after a certain position. Used when overwriting history, e.g.
// drawing while at middle of history stack.
- (void)purgeHistoryAfterCursor{
    //NSLog(@"SketchView.purgeHistoryAfterCursor");
    
    // Return early if there's no history.
    if (!history){
        return;
    }
    
    // Return early if already at last saved state
    if (historyCursor == history.count - 1){
        return;
    }
    
    // Return early if the historyCursor is not valid.
    // Is it possible to end up here?? But this is a fail-safe.
    if (history.count <= historyCursor){
        return;
    }
    
    //NSLog(@"SketchView.purgeHistoryAfterCursor before, historyCursor=%d, history.count=%d", historyCursor, history.count);
    
    // Removing items from the array does not properly release the CGImages, so
    // manually releasing them below.
    //[history removeObjectsInRange:NSMakeRange(historyCursor+1, history.count-(historyCursor+1))];
    
    CGImageRef imageInHistory;
    
    if (history.count > 0){
        //for (int i = historyCursor + 1; i < history.count; i++){
        for (NSUInteger i = history.count - 1; i > historyCursor; i--){
            imageInHistory = (CGImageRef)CFBridgingRetain([history objectAtIndex:i]);
            CGImageRelease(imageInHistory);
            [history removeObjectAtIndex:i];
            imageInHistory = nil;
        }
    }
    
    //NSLog(@"SketchView.purgeHistoryAfterCursor after, historyCursor=%d, history.count=%d", historyCursor, history.count);
}

- (void)goToHistoryCursor{
    //NSLog(@"SketchView.goToHistoryCursor, historyCursor=%d", historyCursor);
    
    // Return early if there's no history.
    if (!history){
        return;
    }
    
    self.modified = YES;
    
    [self releaseFlattened];
    flattenedImage_ = CGImageCreateCopy((__bridge CGImageRef)[history objectAtIndex:historyCursor]);
    [self setNeedsDisplay];
}

-(void)goBackInHistory{
    //NSLog(@"SketchView.goBackInHistory, historyCursor=%d", historyCursor);
    
    // Return early if there's no history.
    if (!history){
        return;
    }

    historyCursor--;
    if (historyCursor >= 0) {
        [self goToHistoryCursor];
    }else{
        historyCursor = 0;
    }
    [self updateUndoRedo];
}

- (void)goForwardInHistory{
    //NSLog(@"SketchView.goForwardInHistory, historyCursor=%d", historyCursor");
    
    // Return early if there's no history.
    if (!history){
        return;
    }
    
    historyCursor++;
    if (historyCursor < history.count){
        [self goToHistoryCursor];
    }else{
        historyCursor--;
    }
    [self updateUndoRedo];
}


- (void)purgeAllHistory{
    
    // Return early if there's no history to purge
    if (!history){
        return;
    }
    
    if (history.count == 0){
        return;
    }
    
    CGImageRef imageInHistory;
    
    for (int i = 0; i < history.count; i++){
        imageInHistory = (CGImageRef)CFBridgingRetain([history objectAtIndex:i]);
        CGImageRelease(imageInHistory);
        [history removeObjectAtIndex:i];
        imageInHistory = nil;
    }

    [self updateUndoRedo];
}

// Updates the undo and redo buttons to reflect if they are enabled, given the
// history's state.
- (void)updateUndoRedo{
    //NSLog(@"SketchView.updateUndoRedo, historyCursor=%ld, history.count=%lu", (long)historyCursor, (unsigned long)history.count);
    
    BOOL undoEnabled = NO;
    BOOL redoEnabled = NO;
    
    if (history){
        if (historyCursor > 0){
            undoEnabled = YES;
        }
        if (historyCursor < (history.count - 1)){
            redoEnabled = YES;
        }
    }
    [self.delegate setUndoButtonEnabled:undoEnabled redoButtonEnabled:redoEnabled];
}











#pragma mark - Clipboard related

- (void)setClipboardContent {
    [self setClipboardContent:[self getUIImage]];
}

- (void)setClipboardContent:(UIImage*)clipboardContent {
    _clipboardContent = clipboardContent;
}

- (UIImage*)clipboardContent {
    return _clipboardContent;
}

- (void)pasteClipboardWithNothingToPasteBlock:(void (^)())nothingToPasteBlock {
    if (_clipboardContent == nil){
        if (nothingToPasteBlock){
            nothingToPasteBlock();
        }
    }
    
    [self initWithUIImage:_clipboardContent];
}

- (BOOL)hasClipboardImage {
    if (_clipboardContent){
        return YES;
    }
    return NO;
}











#pragma mark - Marquee related

- (void)drawMarqueeSourceRectWithAlpha:(CGFloat)alpha inContext:(CGContextRef)context{
    //NSLog(@"drawMarqueeFrom %@ to %@", NSStringFromCGPoint(startPoint), NSStringFromCGPoint(endPoint));
    CGColorRef colorRef;
    
    CGRect srcRect = [self getRectFromMarqueePoints];

    
    // set the drawing color to the stroke's color
    UIColor *strokeColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:alpha]; // 50% opacity gray
    colorRef = [strokeColor CGColor]; // get the CGColor
    
    //Set the blend mode so that whatever is drawn adds to that in the context
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    //CGContextSetBlendMode(context, kCGBlendModeMultiply);
    
    // set the line width to the stroke's line width
    CGContextSetLineWidth(context, 2.0);
    
    CGFloat dashes[] = { 6, 4 };
    CGContextSetLineDash(context, 0.5, dashes, 2);
    CGContextSetLineCap(context, kCGLineCapRound);
    //CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    
    CGContextSetStrokeColorWithColor(context, colorRef);
    
    /*
    // move to the point
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    
    // draw a line to the new point
    CGContextAddLineToPoint(context, endPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextAddLineToPoint(context, startPoint.x, endPoint.y);
    CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
    */
    
    CGContextAddRect(context, srcRect);
    CGContextStrokePath(context);

}

- (CGRect)getRectFromMarqueePoints{
    
    CGPoint lower, higher;
    lower.x = (marqueeStart.x > marqueeEnd.x ? marqueeEnd.x : marqueeStart.x);
    lower.y = (marqueeStart.y > marqueeEnd.y ? marqueeEnd.y : marqueeStart.y);
    higher.x = (marqueeStart.x < marqueeEnd.x ? marqueeEnd.x : marqueeStart.x);
    higher.y = (marqueeStart.y < marqueeEnd.y ? marqueeEnd.y : marqueeStart.y);
    
    // redraw the screen in the required region
    return CGRectMake(lower.x, lower.y, higher.x - lower.x, higher.y - lower.y);
}

// Clear the selected area
- (void)cutOutMarquee{
    
    marqueeDrawn = TRUE;
    CGRect bounds = self.bounds;
    marqueedRect = [self getRectFromMarqueePoints];
    
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat marqueedWidth = CGRectGetWidth(marqueedRect);
    CGFloat marqueedHeight = CGRectGetHeight(marqueedRect);
    
    CGContextRef context = CreateBitmapContext(marqueedWidth, marqueedHeight);
    
    if (context == nil){
        //TODO: Handle this better?
        NSLog(@"Could not create bitmapContent for marqueedImage, failing silenty");
        return;
    }
    
    //NSLog(@"flattenedImage_ dimensions: %lu x %lu", CGImageGetWidth(flattenedImage_), CGImageGetHeight(flattenedImage_));
    
    CGContextClearRect(context, CGRectMake(0, 0, marqueedRect.size.width, marqueedRect.size.height));
    
    
    
    //draw marqueed part into context
    if(flattenedImage_) {
        CGContextDrawImage(context, CGRectMake(-marqueedRect.origin.x, -marqueedRect.origin.y, width, height), flattenedImage_);
    }
    
    // Write out context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"flatten-2.png" isRelativeToDocument:TRUE];
    
    [self releasMarqueedImage];
    marqueedImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    
    
    
    //Clear marqueedRect from flattenedImage_
    context = CreateBitmapContext(width, height);
    
    if (context == nil){
        //TODO: Handle this better?
        NSLog(@"Could not create bitmapContent for flattenedImage minus marqueedImage, failing silenty");
        return;
    }

    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    if(flattenedImage_) {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), flattenedImage_);
    }
    CGContextClearRect(context, marqueedRect);
    
    // Write out context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"flatten-3.png" isRelativeToDocument:TRUE];
    
    [self releaseFlattened];
    flattenedImage_ = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
}

// Place the marquee
-(void)endMarquee{
    [self addMarqueedImageToFlattenedImage];
    //[self flatten];
    marqueedRect = CGRectNull;
    marqueeDrawn = FALSE;
    marqueeStartedDrawing = FALSE;
    //[self penToolSelected];
    [self releasMarqueedImage];
    [self setNeedsDisplay];
}

// Draw selected area into context when placed
-(void)addMarqueedImageToFlattenedImage{

    CGRect bounds = self.bounds;
    CGRect destRect = CGRectMake(marqueedRect.origin.x + (marqueeMoveEnd.x-marqueeMoveStart.x), marqueedRect.origin.y + (marqueeMoveEnd.y-marqueeMoveStart.y), marqueedRect.size.width, marqueedRect.size.height);
    
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    //CGFloat marqueedWidth = CGRectGetWidth(marqueedRect);
    //CGFloat marqueedHeight = CGRectGetHeight(marqueedRect);
    
    CGContextRef context = CreateBitmapContext(width, height);
    
    if (context == nil){
        //TODO: Handle this better?
        NSLog(@"Could not create bitmapContent for flattenedImage minus marqueedImage, failing silenty");
        return;
    }
    
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    
    if(flattenedImage_) {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), flattenedImage_);
    }

    //draw marqueed part into context
    if(marqueedImage) {
        CGContextDrawImage(context, destRect, marqueedImage);
    }
    
    // Write out context to test
    //[RYTSketchViewUtils writeCGImage:CGBitmapContextCreateImage(context) toPath:@"test" withFileName:@"flatten-2.png" isRelativeToDocument:TRUE];
    
    [self releaseFlattened];
    flattenedImage_ = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
}

@end
