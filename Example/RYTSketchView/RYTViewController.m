//
//  RYTViewController.m
//  RYTSketchView
//
//  Created by Ryan on 06/20/2015.
//  Copyright (c) 2014 Ryan. All rights reserved.
//

#import "RYTViewController.h"
#import "RYTSketchOptionsViewController.h"
#import "RYTSketchPenOptionsViewController.h"
#import "UIView+printSubviews.h"
#import <RYTSketchView/RYTJoystickView.h>

@interface RYTViewController () {
    
    UIScrollView *_scrollView;
    RYTSketchView *sketchView;
    RYTJoystickView *joystickView;
    
    NSInteger previousPenColorIndex;
    
    
    //Touch related
    CGPoint startPanLocaton;
    CGPoint startContentOffset;
    //CGFloat startPanDist;
    //CGFloat startZoomScale;
    
    WYPopoverController* _popoverController;
    
}

@property (strong, nonatomic) IBOutlet UIView *sketchViewWrapper;
@property (weak, nonatomic) IBOutlet UIButton *penButton;
@property (weak, nonatomic) IBOutlet UIButton *redPenButton;
@property (weak, nonatomic) IBOutlet UIButton *eraserButton;
@property (weak, nonatomic) IBOutlet UIButton *sketchActionsButton;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *redobutton;
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (strong, nonatomic) IBOutlet UILabel *zoomLabel;

@end


#define SketchViewMinBorderForPan 400

@implementation RYTViewController

/*
- (void)loadView {
    UIView *theView = [[UIView alloc]init];
    
    
    
    
    self.view = theView;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Test multi touch
    //self.view.multipleTouchEnabled = TRUE;
    
    self.penButton.alpha = 1.0;
    self.redPenButton.alpha = 0.2;
    self.eraserButton.alpha = 0.2;
    
    
    //Init scroll view
    CGRect scrollFrame;
    //scrollFrame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_HEIGHT);
    scrollFrame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - 48);
    NSLog(@"scrollFrame=%@", NSStringFromCGRect(scrollFrame));
    
    _scrollView = [[UIScrollView alloc] initWithFrame:scrollFrame];
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    _scrollView.pagingEnabled = NO; //do not snap to multiples of ZoomScale and position
    _scrollView.scrollEnabled = FALSE; // Diable one-finger scrolling
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.maximumZoomScale = _scrollView.minimumZoomScale;
    _scrollView.multipleTouchEnabled = TRUE;
    _scrollView.zoomScale = _scrollView.minimumZoomScale;

    CGRect sketchFrame = (CGRect){
        .origin = CGPointZero,
        .size = scrollFrame.size
        //.size = CGSizeMake(scrollFrame.size.width  * 2, scrollFrame.size.height * 2)
    };
    sketchView = [[RYTSketchView alloc]initWithFrame:sketchFrame];
    sketchView.delegate = self;
    sketchView.zoomEnabled = YES;
    sketchView.shouldStoreHistory = YES;
    
    // Enable zooming
    if (sketchView.zoomEnabled){
        _scrollView.showsHorizontalScrollIndicator = TRUE;
        _scrollView.showsVerticalScrollIndicator = TRUE;
        
        // Derive min and max zoom from zoomSlider.
        _scrollView.minimumZoomScale = self.zoomSlider.minimumValue;
        _scrollView.maximumZoomScale = self.zoomSlider.maximumValue;
        
        // Set initial zoom.
        self.zoomSlider.value = 1.0;
    }
    
    //test, block 2 finger pan
    /*UIPanGestureRecognizer *twoFingerPan = [[UIPanGestureRecognizer alloc] init];
     twoFingerPan.minimumNumberOfTouches = 2;
     twoFingerPan.maximumNumberOfTouches = 2;
     [_scrollView addGestureRecognizer:twoFingerPan];*/
    
    for (UIGestureRecognizer* recognizer in [_scrollView gestureRecognizers]) {
        //[_scrollView removeGestureRecognizer:recognizer];
        /*if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
         [recognizer setEnabled:NO];
         }*/
        [recognizer setEnabled:NO];
    }
    
    // Add sub views
    [_scrollView insertSubview:sketchView atIndex:0];
    [_sketchViewWrapper insertSubview:_scrollView atIndex:0];
    
    // Debug: check view hierarchy
    //[self.view printSubviewsWithIndentation:0];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self layoutSubviewsCustom];
    
    // Pass message on to view
    [sketchView viewWillAppear];
    
    // Register for keyboard notifications.
    // Deprecated, was used for the text tool.
    //[[NSNotificationCenter defaultCenter] addObserver:self
    //                                         selector:@selector(keyboardWillShow:)
    //                                             name:UIKeyboardWillShowNotification
    //                                           object:nil];
    //
    //[[NSNotificationCenter defaultCenter] addObserver:self
    //                                         selector:@selector(keyboardWillHide:)
    //                                             name:UIKeyboardWillHideNotification
    //                                           object:nil];
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"SketchViewController.willAnimateRotationToInterfaceOrientation:(%@)duration:(%f)", (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)?@"Portrait":@"Landscape"), duration);
    [self layoutSubviewsCustomForOrientation:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}









#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return sketchView;
}

- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
    
    CGSize boundsSize = scroll.bounds.size;
    CGRect frameToCenter = rView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }else{
        frameToCenter.origin.x = 0;
    }
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0;
    }
    return frameToCenter;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    sketchView.frame = [self centeredFrameForScrollView:scrollView andUIView:sketchView];
    
    // TODO: Refactor
    [self autoHideJoystick];
}






#pragma mark - RYTPopoverDelegate

- (void)popover:(UIPopoverController *)popoverController dismissAnimated:(BOOL)animated {
    [popoverController dismissPopoverAnimated:animated];
}

- (void)dismissPopoversAnimated:(BOOL)animated {
    [_popoverController dismissPopoverAnimated:animated];
}









#pragma mark - JoystickViewControllerDelegate

- (void)joystick:(RYTJoystickView *)joystick moved:(CGPoint)delta{
    
    if (_scrollView.zoomScale == 1.0){
        //ignore
        return;
    }
    
    
    CGPoint offset;
    if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])){
        if ((_scrollView.contentSize.width < SCREEN_WIDTH) || (_scrollView.contentSize.height < 861)){
            //ignore
            return;
        }
        offset = CGPointMake(delta.x * (_scrollView.contentSize.width-SCREEN_WIDTH), delta.y * (_scrollView.contentSize.height-861));
    }else {
        if ((_scrollView.contentSize.width < SCREEN_HEIGHT) || (_scrollView.contentSize.height < 605)){
            //ignore
            return;
        }
        offset = CGPointMake(delta.x * (_scrollView.contentSize.width-SCREEN_HEIGHT), delta.y * (_scrollView.contentSize.height-605));
    }
    NSLog(@"offset=%@", NSStringFromCGPoint(offset));
    _scrollView.contentOffset = offset;
}




#pragma mark - SketchViewDelegate

- (void)handlePan:(UIPanGestureRecognizer *)recognizer translation:(CGPoint)translation{
    NSLog(@"SketchViewController.handlePan, translation=%@", NSStringFromCGPoint(translation));
    //_scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x+translation.x, _scrollView.contentOffset.y+translation.y);
    
    if (recognizer.state == UIGestureRecognizerStateBegan){
        startPanLocaton = translation;
    }else if (recognizer.state == UIGestureRecognizerStateEnded){
    }else{
        _scrollView.contentOffset = CGPointMake(-translation.x, -translation.y);
    }
}

- (void)handlePan:(CGPoint)p1 and:(CGPoint)p2 phase:(NSInteger)phase{
    
    CGFloat centerX = (fabs(p1.x+p2.x))/2;
    CGFloat centerY = (fabs(p1.y+p2.y))/2;
    CGPoint center = CGPointMake(centerX, centerY);
    
    if (phase == 1){
        //startPanDist = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
        //startZoomScale = _scrollView.zoomScale;
        startPanLocaton = center;
        //NSLog(@"\tstartPanLocaton=%@", NSStringFromCGPoint(startPanLocaton));
        startContentOffset = _scrollView.contentOffset;
        //NSLog(@"\tstartContentOffset=%@", NSStringFromCGPoint(startContentOffset));
    }else if (phase == 2){
        //CGFloat currDist = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
        //CGFloat scaleDelta = sqrt(currDist/startPanDist);
        //_scrollView.zoomScale = startZoomScale * scaleDelta;
        
        CGFloat targetOffsetX = startPanLocaton.x-center.x+startContentOffset.x;
        CGFloat targetOffsetY = startPanLocaton.y-center.y+startContentOffset.y;
        //NSLog(@"\ttargetOffset=%@", NSStringFromCGPoint(CGPointMake(targetOffsetX, targetOffsetY)));
        
        //Prevent from moving off screen
        if (targetOffsetX > (_scrollView.contentSize.width - SketchViewMinBorderForPan)){
            targetOffsetX = _scrollView.contentSize.width - SketchViewMinBorderForPan;
        }else if (targetOffsetX < -self.view.frame.size.width + SketchViewMinBorderForPan) {
            targetOffsetX = -self.view.frame.size.width + SketchViewMinBorderForPan;
        }
        
        if (targetOffsetY > (_scrollView.contentSize.height-SketchViewMinBorderForPan)){
            targetOffsetY = _scrollView.contentSize.height-SketchViewMinBorderForPan;
        }else if (targetOffsetY < -self.view.frame.size.height + SketchViewMinBorderForPan) {
            targetOffsetY = -self.view.frame.size.height + SketchViewMinBorderForPan;
        }
        _scrollView.contentOffset = CGPointMake(targetOffsetX, targetOffsetY);
        //NSLog(@"\t_scrollView.contentOffset=%@", NSStringFromCGPoint(_scrollView.contentOffset));
    }
    
    
    
}

- (UIView *)viewForTouch{
    //return _scrollView;
    return self.view;
}

- (void)setUndoButtonEnabled:(BOOL)undoEnabled redoButtonEnabled:(BOOL)redoEnabled {
    //NSLog(@"SketchViewController.setUndoButtonEnabled:%@ redoButtonEnabled:%@",(undoEnabled?@"YES":@"NO"),(redoEnabled?@"YES":@"NO"));
    self.undoButton.enabled = undoEnabled;
    self.redobutton.enabled = redoEnabled;
}


- (void)zoomInToPoint:(CGPoint)point{
    //TODO: Set proper contentOffset
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (_scrollView.zoomScale > 1){
            _scrollView.contentOffset = CGPointZero;
            _scrollView.zoomScale = 1;
        }else{
            
            //CGRect contentFrame = self.currentSketchView.frame;
            CGRect bounds = self.view.bounds;
            CGFloat newZoom = _scrollView.maximumZoomScale;
            
            //NSLog(@"contentFrame=%@, bounds=%@", NSStringFromCGRect(contentFrame), NSStringFromCGRect(bounds));
            
            //_scrollView.contentOffset = CGPointMake((point.x * newZoom) - (bounds.size.width/2), (point.y * newZoom) - (bounds.size.height/2));
            //_scrollView.contentOffset = CGPointMake(50, 50);
            //_scrollView.contentOffset = CGPointMake(point.x/newZoom, point.y/newZoom);
            _scrollView.contentOffset = CGPointMake((point.x) - (bounds.size.width/2), (point.y) - (bounds.size.height/2));
            //NSLog(@"new offset = %@", NSStringFromCGPoint(_scrollView.contentOffset));
            _scrollView.zoomScale = newZoom;
        }
    } completion:^(BOOL finished) {
        //do nothing
    }];
    
}







#pragma mark - IBActions

- (IBAction)sketchActionsTapped:(id)sender {
    
    RYTSketchOptionsViewController *sketchOptionsController = [[RYTSketchOptionsViewController alloc] init];
    sketchOptionsController.sketchView = sketchView;
    
    UIView *triggerButton = (UIView*)sender;
    //CGRect sourceFrame = CGRectMake(triggerButton.frame.origin.x, triggerButton.frame.origin.y+44, triggerButton.frame.size.width, triggerButton.frame.size.height);
    
    // Show in UIPopoverController.
    //UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:sketchOptionsController];
    //sketchOptionsController.popoverController = pc;
    //[pc presentPopoverFromRect:triggerButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    
    // Show in WYPopoverController.
    _popoverController = [[WYPopoverController alloc] initWithContentViewController:sketchOptionsController];
    _popoverController.delegate = self;
    sketchOptionsController.popoverDelegate = self;
    [_popoverController presentPopoverFromRect:triggerButton.frame inView:self.view permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
}

- (IBAction)undoTapped:(id)sender {
    [sketchView goBackInHistory];
}

- (IBAction)redoTapped:(id)sender {
    [sketchView goForwardInHistory];
}

- (IBAction)penOptionsTapped:(id)sender {
    NSLog(@"penToolSelected");
    
    // If the pen was already selected, show options
    if ([sketchView currentTool] == RYTSketchToolTypePen || [sketchView currentTool] == RYTSketchToolTypeMarquee){
        
        if (self.redPenButton.selected){
            [sketchView penToolSelectedWithColorIndex:previousPenColorIndex];
            self.redPenButton.selected = NO;
        }else{
            [self showPenOptionsFromButton:sender];
        }
    }
    
    self.penButton.alpha = 1.0;
    self.redPenButton.alpha = 0.2;
    self.eraserButton.alpha = 0.2;
    [sketchView penToolSelected];
    
}

- (IBAction)penRedTapped:(id)sender {
    //[sketchView penToolSelectedWithColor:5];
    
    
    self.penButton.alpha = 0.2;
    self.redPenButton.alpha = 1.0;
    self.eraserButton.alpha = 0.2;
    
    //if ([sketchView currentTool] == RYTSketchToolTypePen){
        if (self.redPenButton.selected){
            // Restore previous color
            [sketchView penToolSelectedWithColorIndex:previousPenColorIndex];
            self.redPenButton.selected = FALSE;
            //[self.redPenButton setBackgroundImage:[UIImage imageNamed:@"penBlack"] forState:UIControlStateNormal];
            //[self.redPenButton setBackgroundImage:[UIImage imageNamed:@"penRuby"] forState:UIControlStateNormal];
            
            self.penButton.alpha = 1.0;
            self.redPenButton.alpha = 0.2;
            self.eraserButton.alpha = 0.2;
        }else{
            // Store previous pen color
            previousPenColorIndex = sketchView.penColorIndex;
            
            // Set to red
            [sketchView penToolSelectedWithColorIndex:5];
            self.redPenButton.selected = TRUE;
            //[self.redPenButton setBackgroundImage:[UIImage imageNamed:@"penRuby-selected"] forState:UIControlStateNormal];
        }
    /*}else{
        if (self.redPenButton.selected){
            [sketchView penToolSelectedWithColor:5];
        }else{
            [sketchView penToolSelectedWithColor:1];
        }
    }*/
}

- (IBAction)eraserTapped:(id)sender {
    NSLog(@"eraserToolSelected");

    self.penButton.alpha = 0.2;
    self.redPenButton.alpha = 0.2;
    self.eraserButton.alpha = 1.0;
    [sketchView eraserToolSelected];
}

- (IBAction)zoomValueChanged:(id)sender {
    
    if (fabs(1.0 - self.zoomSlider.value) < 0.07) {
        self.zoomSlider.value = 1.0;
    }
    
    [self zoomAccordingToSliderZoom];
}





#pragma mark - WYPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller {
    _popoverController.delegate = nil;
    _popoverController = nil;
}






#pragma mark - Custom

- (void)showPenOptionsFromButton:(id)sender {
    RYTSketchPenOptionsViewController *penOptionsController = [[RYTSketchPenOptionsViewController alloc] init];
    penOptionsController.sketchView = sketchView;
    
    UIView *triggerButton = (UIView*)sender;
    
    // Show in UIPopoverController.
    //UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:penOptionsController];
    //penOptionsController.popoverController = pc;
    //[pc presentPopoverFromRect:triggerButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    // Show in WYPopoverController.
    _popoverController = [[WYPopoverController alloc] initWithContentViewController:penOptionsController];
    _popoverController.delegate = self;
    penOptionsController.popoverDelegate = self;
    [_popoverController presentPopoverFromRect:triggerButton.frame inView:self.view permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
}

- (void)zoomAccordingToSliderZoom{
    //NSLog(@"zoomAccordingToSliderZoom, zoomSlider.value=%f", _zoomSlider.value);
    //_scrollView.zoomScale = ((_scrollView.maximumZoomScale-_scrollView.minimumZoomScale) * self.zoomSlider.value) + _scrollView.minimumZoomScale;
    //NSLog(@"_scrollView.zoomScale: %f", _scrollView.zoomScale);
    _scrollView.zoomScale = _zoomSlider.value;
    [_scrollView flashScrollIndicators];
    self.zoomLabel.text = [NSString stringWithFormat:@"Zoom: %4.2f", self.zoomSlider.value];
}


- (void)layoutSubviews{
    [self layoutSubviewsCustom];
}

- (void)layoutSubviewsCustom{
    [self layoutSubviewsCustomForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)layoutSubviewsCustomForOrientation:(UIInterfaceOrientation)orientation {
    Boolean isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    NSLog(@"SketchViewController.layoutSubviewsCustomForOrientation, isPortrait = %@", (isPortrait?@"YES":@"NO"));
    
    NSLog(@"BEFORE: sketchView.frame=%@", NSStringFromCGRect(sketchView.frame));
    
    BOOL keepOrientation = FALSE;
    
    // NOTE: sketchView frames doesn't change. The zoom of _scrollView does
    
    // For testing
    BOOL isEditingWO = NO;
    
    // Calculate the right zoomScale
    if (isPortrait){
     
        if (isEditingWO){
            if (keepOrientation){
                //Remove rotation (if it was applied)
                sketchView.transform = CGAffineTransformIdentity;
            }
        }
     
        // TODO: Convert to relative value
        joystickView.center = CGPointMake(70, 838);
     
    }else{
        if (isEditingWO){
            if (keepOrientation){
                
                // Use a transform to preserve orientation
                CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
                sketchView.transform = transform;
                    //NOTE: Do not use UIVIew.frame after setting transform. It is undefined
            }
        }
        
        // TODO: Convert to relative value
        joystickView.center = CGPointMake(70, 579);
    }
    
    // init scrollView
    //_scrollView.contentSize = sketchView.bounds.size;
    //_scrollView.minimumZoomScale = zoomScale;
    //_scrollView.maximumZoomScale = zoomScale * (sketchView.zoomEnabled ? 4 : 1);
    
    //[_scrollView setZoomScale:zoomScale animated:TRUE];
    //[_scrollView setContentOffset:CGPointMake(0, 0) animated:TRUE];
    //NSLog(@"zoomScale = %f", zoomScale);
    
    [self zoomAccordingToSliderZoom];
    
    [joystickView resetJoystick];
    
    if (sketchView.joystickEnabled) {
        [self.view addSubview:joystickView];
    }else{
        [joystickView removeFromSuperview];
    }
    
    [self autoHideJoystick];
    
    
    for (UIGestureRecognizer* recognizer in [_scrollView gestureRecognizers]) {
        //[_scrollView removeGestureRecognizer:recognizer];
        //if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        //  [recognizer setEnabled:NO];
        //}
        [recognizer setEnabled:NO];
    }
    
    // DEBUG:
    NSLog(@"sketchView.transform = %@", NSStringFromCGAffineTransform(sketchView.transform));
    NSLog(@"AFTER: sketchView.frame=%@", NSStringFromCGRect(sketchView.frame));
    NSLog(@"AFTER: sketchView.bounds=%@", NSStringFromCGRect(sketchView.bounds));
}


- (void)autoHideJoystick{
    if ((_scrollView.contentSize.width > (_scrollView.frame.size.width+10)) || (_scrollView.contentSize.height > (_scrollView.frame.size.height+10))){
        joystickView.alpha=1;
    }else{
        joystickView.alpha = 0.3;
    }
}



@end
