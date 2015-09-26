//
//  SketchView.h
//  RYTSketchView
//
//  Created by Ryan Tan on 1/9/11.
//  Copyright (c) 2011 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stroke.h"

// TODO: Deprecate
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

typedef enum {
    RYTSketchToolTypePen = 0,
    RYTSketchToolTypeEraser,
    RYTSketchToolTypeText,
    RYTSketchToolTypeMarquee
} RYTSketchToolType;

@protocol RYTSketchViewDelegate <NSObject>

- (void)handlePan:(UIPanGestureRecognizer *)recognizer translation:(CGPoint)translation;
- (void)handlePan:(CGPoint)p1 and:(CGPoint)p2 phase:(NSInteger)phase;
- (UIView*)viewForTouch;
- (void)setUndoButtonEnabled:(BOOL)undoEnabled redoButtonEnabled:(BOOL)redoEnabled;
- (void)zoomInToPoint:(CGPoint)point;

@end

@interface RYTSketchView : UIView 

@property (nonatomic, strong) id<RYTSketchViewDelegate> delegate;
@property (nonatomic, assign) RYTSketchToolType currentTool;
@property (nonatomic, strong) UIColor *penColor;
@property (nonatomic, assign) NSInteger penColorIndex;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) NSInteger eraserThickness;
@property (nonatomic, assign) BOOL unfocused;
@property (nonatomic, assign) BOOL modified;
@property (nonatomic, strong) NSString *debugOutput;

@property (nonatomic, assign) BOOL zoomEnabled;
@property (nonatomic, assign) BOOL shouldStoreHistory;
@property (nonatomic, assign) NSInteger maxHistoryStates;
@property (nonatomic, assign) BOOL joystickEnabled;



- (void)initView;
- (void)viewWillAppear;
- (void)clearSketch; // clear all strokes from the view
- (void)clearSketchInternal;
//- (void)resetView; //prepare sketch to load another sketch
- (void)canvasWillReset; //prepare canvas to load another sketch
- (void)prepareForSketching; //prepare canvas to be ready for sketching
- (void)penToolSelected;
- (void)penToolSelectedWithColorIndex:(NSInteger)colorIndex;
- (void)penToolSelectedWithColor:(UIColor*)color;
- (void)eraserToolSelected;
- (void)textToolSelected;
- (void)marqueeToolSelected;



//Touch related
//- (UITouch*)filterTouches:(NSArray*)array;
- (NSString*)getKeyFromTouch:(UITouch*)touch;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;



//Strokes management
- (Stroke*)getStrokeForTouch:(UITouch*)touch;
- (void)setStroke:(Stroke*)stroke forTouch:(UITouch*)touch;
- (void)removeStrokeByTouch:(UITouch*)touch;



//Graphics Related
- (void)drawRectWithExtraContext:(CGRect)rect;
// draw the given Stroke into the given graphics context
- (void)drawStroke:(Stroke *)Stroke inContext:(CGContextRef)context;
- (void)flatten; //draw all paths into bitmap context
- (UIImage *)getUIImage;
- (UIImage *)getThumbnail;
- (void)initWithUIImage:(UIImage*)sketch;
- (void)setTemplate:(UIImage*)template;



//Pen options
- (void)setPenThickness:(NSInteger)thickness;
- (NSInteger)getPenThickness;



//Undo Redo
- (void)saveHistory;
- (void)purgeHistoryAfterCursor;
- (void)goToHistoryCursor;
- (void)goBackInHistory;
- (void)goForwardInHistory;
- (void)purgeAllHistory;


// Clipboard
- (void)setClipboardContent;
- (void)setClipboardContent:(UIImage*)clipboardContent;
- (UIImage*)clipboardContent;
//- (NSInteger)pasteClipboard;
- (void)pasteClipboardWithNothingToPasteBlock:(void (^)())nothingToPasteBlock;
- (BOOL)hasClipboardImage;


//Marquee related
- (void)drawMarqueeSourceRectWithAlpha:(CGFloat)alpha inContext:(CGContextRef)context;
- (CGRect)getRectFromMarqueePoints;
- (void)cutOutMarquee;
- (void)endMarquee;
- (void)addMarqueedImageToFlattenedImage;


@end
