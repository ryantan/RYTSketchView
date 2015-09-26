//
//  SketchViewController.m
//  RYTSketchView
//
//  Created by Ryan Tan on 9/12/11.
//  Copyright 2011 Ryan Tan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIView+LayoutHelper.h"
#import "MBProgressHUD.h"

#import "RYTSketchViewUtils.h"

#import "SketchViewController.h"
#import "RYTSketchView.h"

#import "RYTJoystickView.h"

// View Controllers
#import "UIImageView+ForScrollView.h"
#import "RYTPenOptionsViewController.h"
//#import "ClothsetOptionsPopoverController.h"
//#import "RSAttachImageViewController.h"
//#import "RSPhotosViewController.h"


#define MOVE_ANIMATION_DURATION_SECONDS 2
#define ZOOM_ENABLED 1
#define USING_CHINESE_OPTIONS 0

#define SketchViewMinBorderForPan 400
//#define MeasurementsSavingWaitingViewTag 201
//#define SketchSavingWaitingViewTag 202

@interface SketchViewController () {
    //RSAttachImageViewController *attachImageView;
    
    // UI
    UIButton *btnPhotos;
    MBProgressHUD *hud;
}

@end

@implementation SketchViewController



//@synthesize workorder;
//@synthesize workorderSplitViewController;

@synthesize viewSketchTools = _viewSketchTools;
@synthesize toolbarIsHidden;

// Popover and panels
//@synthesize workorderInfoPanel = _workorderInfoPanel;
//@synthesize workorderInfoPanelPopover = _workorderInfoPanelPopover;

//@synthesize sketchOptionsPanel = _sketchOptionsPanel;
//@synthesize sketchOptionsPanelPopover = _sketchOptionsPanelPopover;

//@synthesize currentSetSelectorIndex = _currentSetSelectorIndex;

@synthesize zoomEnabled;
@synthesize shouldShowJoystick;


#pragma mark - View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set toolbar to Orange color
    //self.viewSketchTools.backgroundColor = [UIColor colorWithRed:233.0/255.0 green:134.0/255.0 blue:44.0/255.0 alpha:1.0];
    
    // Test multi touch
    //self.view.multipleTouchEnabled = TRUE;
    
    btnPhotos = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPhotos.frame = CGRectMake(btnRedo.frame.origin.x+btnRedo.bounds.size.width + 5, btnRedo.frame.origin.y, btnRedo.bounds.size.width, btnRedo.bounds.size.height);
    [btnPhotos setBackgroundImage:[UIImage imageNamed:@"iconCamera"] forState:UIControlStateNormal];
    [btnPhotos addTarget:self action:@selector(photosTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewSketchTools addSubview:btnPhotos];
    
    //lblClothsetID.alpha = 0.0;
    
    btnPen.alpha = 1.0;
    btnEraser.alpha = 0.2;
    
    
    theSketchView =[[RYTSketchView alloc]initWithFrame:self.view.bounds];
    theSketchView.delegate = self;
    [theSketchView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];

    
    //Init scroll view
    CGRect scrollFrame;
    //scrollFrame= CGRectMake(0, 0, SCREEN_WIDTH, 911);
    scrollFrame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_HEIGHT);
    //NSLog(@"scrollFrame=%@", NSStringFromCGRect(scrollFrame));
    scrollView = [[UIScrollView alloc] initWithFrame:scrollFrame];
    scrollView.delegate = self;
    scrollView.tag = 836913;
    scrollView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    //scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.pagingEnabled = NO; //do not snap to multiples of ZoomScale and position
    
    
    
    if (self.zoomEnabled){
        //scrollView.scrollEnabled = TRUE; //1 finger scrolling
        scrollView.scrollEnabled = FALSE;
        scrollView.showsHorizontalScrollIndicator = TRUE;
        scrollView.showsVerticalScrollIndicator = TRUE;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 3.0;
        scrollView.multipleTouchEnabled = TRUE;
        
    }else{
        //Disable zooming
        //Don't want the view to scroll while the user sketch
        scrollView.scrollEnabled = FALSE;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = scrollView.minimumZoomScale;
        scrollView.multipleTouchEnabled = TRUE;
    }
    
    //test, block 2 finger pan
    /*UIPanGestureRecognizer *twoFingerPan = [[UIPanGestureRecognizer alloc] init];
    twoFingerPan.minimumNumberOfTouches = 2;
    twoFingerPan.maximumNumberOfTouches = 2;
    [scrollView addGestureRecognizer:twoFingerPan];*/
    
    for (UIGestureRecognizer* recognizer in [scrollView gestureRecognizers]) {
        //[scrollView removeGestureRecognizer:recognizer];
        /*if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
            [recognizer setEnabled:NO];
        }*/
        [recognizer setEnabled:NO];
    }
    
    [scrollView setZoomScale:scrollView.minimumZoomScale];
    [workOrderView insertSubview:scrollView belowSubview:self.viewSketchTools];
    [scrollView insertSubview:theSketchView atIndex:0];
    
    // When using the scrollView, sketchView frames doesn't change. The zoom does
    // Assuming portrait?
    theSketchView.frame = CGRectMake(0, 0, 1210, 655);
    
    
    isShowingKeyboard = FALSE;
    
    //[workOrderView addSubview:fabricsView];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];    

    [btnPenRed setBackgroundImage:[UIImage imageNamed:@"penBlack"] forState:UIControlStateNormal];
    [btnPenRed setBackgroundImage:[UIImage imageNamed:@"penRuby"] forState:UIControlStateSelected];
    btnPenRed.adjustsImageWhenHighlighted = FALSE;
    
    //Joystick should be above fabricsView and option buttons
    joystickView = [[RYTJoystickView alloc]initWithFrame:CGRectMake(10, 779, 120, 120)];
    joystickView.delegate = self;
    [workOrderView addSubview:joystickView];
    
    
    // TODO: What's this for?
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideHistorySmall) name:@"backToSketch" object:nil];
    
    [self layoutSubviewsCustom];
    
    
    //UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(newClothsetLongPressed:)];
    //[btnNewClothset.customView addGestureRecognizer:longPressRecognizer];
        
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    
    // Release any retained subviews of the main view.
    
    theSketchView = nil;
    
    btnSave = nil;
    
    //lblControlPoints = nil;
    //switchControlPoints = nil;
    
    workOrderView = nil;
    
    [self setViewSketchTools:nil];
    btnPen = nil;
    
    //lblTitle = nil;
    sliderZoom = nil;
    btnHideBar = nil;
    btnRedo = nil;
    toolBarView = nil;
    btnPenRed = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"SketchViewController::viewWillAppear");
    
    
    // Hide previously opened sketch if required
    //if (should_reset_sketch){
    //    [theSketchView resetView];
    //}
    
    [self layoutSubviewsCustom];
    
    // Pass message on to view
    // @TODO: Consider using willMoveToSuperview.
    [self.currentSketchView viewWillAppear];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"SketchViewController::viewDidAppear");
    
    //if (should_select_template){
    //    [self waitAndShowTemplateSelector];
    //}
}

- (void)viewWillDisappear:(BOOL)animated{
    NSLog(@"SketchViewController.viewWillDisappear");
    
    [self saveChangesBeforeExit];
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)viewDidLayoutSubviews{
    NSLog(@"SketchViewController.viewDidLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    NSLog(@"SketchViewController.willAnimateRotationToInterfaceOrientation:(%@)duration:(%f)", (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)?@"Portrait":@"Landscape"), duration);
    [self layoutSubviewsCustomForOrientation:toInterfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //NSLog(@"SketchViewController.willRotateToInterfaceOrientation:(%@)duration:(%f)", (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)?@"Portrait":@"Landscape"), duration);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    NSLog(@"SketchViewController.didRotateFromInterfaceOrientation");
    
    // TODO: Check if required
    //[self layoutSubviewsCustom];
}






















#pragma mark - IBActions

/*
- (IBAction)btnTemplates:(id)sender {
    [self showTemplateSelector];
}

- (IBAction)showSketchOptionsPanelTapped:(id)sender {
    //[self showClothsetPanel:sender];
    [self showSketchOptionsPanel:sender];
}

- (IBAction)showWorkorderInfoPanelTapped:(id)sender {
    [self showWorkorderInfoPanel:sender];
}

- (IBAction)showFabricPanelTapped:(id)sender {
    [self showFabricPanel:sender];
}

- (IBAction)measurementsTapped:(id)sender {
    [self showMeasurementPanel2];
}

- (IBAction)setSelectorChanged:(id)sender {
    self.currentSetSelectorIndex = btnSetSelector2.selectedSegmentIndex;
}

- (IBAction)newClothsetTapped:(id)sender {
    [self addNewClothset];
}

- (void)newClothsetLongPressed:(id)sender {
    NSLog(@"newClothsetLongPressed");
    //[self addNewClothset];
}
*/

/*
- (IBAction)saveTapped:(id)sender {
    if (self.currentSetSelectorIndex == 0){
        [self saveMeasureSketchOnComplete:^(void) {
            //do nothing
        }];
    }else{
        [self saveClothsetSketchOnComplete:^(void) {
            //do nothing
        }];
    }
}
*/

- (void)undoTapped:(id)sender{
    [self.currentSketchView goBackInHistory];
}

- (void)redoTapped:(id)sender{
    [self.currentSketchView goForwardInHistory];
}

// Triggered by CSOptionsPopover
- (void)deleteTapped:(id)sender {
    [self willDeleteClothset];
}

- (IBAction)csOptionsTapped:(id)sender {
    [self showClothsetOptions];
}

// Triggered by CSOptionsPopover
- (void)clearSketchTapped:(id)sender {
    [self clearSketch];
}

- (IBAction)penToolSelected:(id)sender {
    NSLog(@"penToolSelected");
    
    if ([self.currentSketchView currentTool] == RSSketchToolTypePen || [self.currentSketchView currentTool] == RSSketchToolTypeMarquee){
        //if was already pen, show options
        [self showPenOptionsFromButton:sender];
    }
    
    btnPen.alpha = 1.0;
    btnPenRed.alpha = 1.0;
    btnEraser.alpha = 0.2;
    [self.currentSketchView penToolSelected];
}

- (IBAction)penToolSelectedRed:(id)sender {
    NSLog(@"penToolSelectedRed");
    
    if ([self.currentSketchView currentTool] == RSSketchToolTypePen){
        if (btnPenRed.selected){
            [self.currentSketchView penToolSelectedWithColor:1];
            btnPenRed.selected = FALSE;
            [btnPenRed setBackgroundImage:[UIImage imageNamed:@"penBlack"] forState:UIControlStateNormal];
        }else{
            [self.currentSketchView penToolSelectedWithColor:5];
            btnPenRed.selected = TRUE;
            [btnPenRed setBackgroundImage:[UIImage imageNamed:@"penRuby"] forState:UIControlStateNormal];
        }
    }else{
        btnPen.alpha = 1.0;
        btnPenRed.alpha = 1.0;
        btnEraser.alpha = 0.2;
        if (btnPenRed.selected){
            [self.currentSketchView penToolSelectedWithColor:5];
        }else{
            [self.currentSketchView penToolSelectedWithColor:1];
        }
    }
    
}

- (IBAction)eraserToolSelected:(id)sender {
    NSLog(@"eraserToolSelected");
    
    [self.currentSketchView flatten];
    btnPen.alpha = 0.2;
    btnPenRed.alpha = 0.2;
    btnEraser.alpha = 1.0;
    [self.currentSketchView eraserToolSelected];
}

- (IBAction)textToolSelected:(id)sender {
    [self.currentSketchView textToolSelected];
}

- (IBAction)sliderZoomChanged:(id)sender {
    [self zoomAccordingToSliderZoom];
}

- (void)photosTapped:(id)sender {
    
    // Dismiss existing popover controllers.
    if (mainPopoverController != Nil){
        [mainPopoverController dismissPopoverAnimated:YES];
        mainPopoverController = Nil;
    }

    // TODO: Initialize view, nav and popover controllers
    
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photosViewController];
    
    //mainPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    
    // Calculate where we are showing the popover
    CGRect popoverRect = [self.viewSketchTools convertRect:((UIView*)sender).frame toView:self.view];
    
    // Present the popover
    [mainPopoverController presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}


















#pragma mark - Custom Status getters


//TODO: Refactor out this function
- (RYTSketchView*) currentSketchView{
    return theSketchView;
}

/*
- (void)setCurrentSetSelectorIndex:(NSInteger)currentSetSelectorIndex{

    //Store previous selection
    previousSetSelectorIndex = _currentSetSelectorIndex;
    
    //Update
    _currentSetSelectorIndex = currentSetSelectorIndex;
    
    NSLog(@"willSwitchEditMode, previousSetSelectorIndex=%ld, currentSetSelectorIndex=%ld", (long)previousSetSelectorIndex, (long)currentSetSelectorIndex);
    [self willSwitchEditMode];
}

- (NSInteger)currentSetSelectorIndex{
    return _currentSetSelectorIndex;
}

*/





















#pragma mark - Custom - Layout

- (void)layoutSubviews{
    [self layoutSubviewsCustom];
    return;
}

- (void)layoutSubviewsCustom{
    [self layoutSubviewsCustomForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)layoutSubviewsCustomForOrientation:(UIInterfaceOrientation)orientation {
    Boolean isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    NSLog(@"SketchViewController.layoutSubviewsCustomForOrientation, isPortrait = %@", (isPortrait?@"YES":@"NO"));
    
    
    //NSLog(@"BEFORE: sketchViewWO.frame=%@", NSStringFromCGRect(sketchViewWO.frame));
    //NSLog(@"BEFORE: sketchViewCS.frame=%@", NSStringFromCGRect(sketchViewCS.frame));
    
    BOOL keepOrientationForWO = FALSE;
    
    // Using scrollview
    float zoomScale = 1.0;
    
    // NOTE: sketchView frames doesn't change. The zoom of scrollView does

    
    /* Causes blurring.
    if ([self isEditingWO]){
        theSketchView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 911);
    }else{
        theSketchView.frame = CGRectMake(0, 0, 1210, 655);
    }
    */
    
    /*
    if (isPortrait){
        
        if ([self isEditingWO]){
            
            if (keepOrientationForWO){
                //Remove rotation (if it was applied)
                //sketchViewWO.transform = CGAffineTransformIdentity;
                theSketchView.transform = CGAffineTransformIdentity;
            }
            
            //zoomScale = 1.0; //NSLog(@"zoomScale = %f", zoomScale);
            zoomScale = SCREEN_WIDTH/1210.0;
            
            
            // layout scrollView]
            scrollView.contentSize = self.currentSketchView.bounds.size;
            scrollView.minimumZoomScale = zoomScale;
            scrollView.maximumZoomScale = zoomScale;
            if (ZOOM_ENABLED){
                scrollView.maximumZoomScale = zoomScale*4;    
            }
            [scrollView setZoomScale:zoomScale animated:TRUE];
            [scrollView setContentOffset:CGPointMake(0, 0) animated:TRUE];
            //[scrollView setContentOffset:CGPointMake(0, 50) animated:TRUE];
            
            viewOptionButtonsShirt.frame = CGRectMake(0, 640, 200, 140);
            viewOptionButtonsPants.frame = CGRectMake(0, 562, 200, 220);
            viewOptionButtonsJacket.frame = CGRectMake(0, 520, 410, 370);
            
        }else{
            // get the exact zoomScale by width ratio
            CGFloat zoomScale = SCREEN_WIDTH/1210.0;
            // get the exact zoomScale by height ratio
            //CGFloat maxZoomScale = 891/655;
            //NSLog(@"zoomScale = %f", zoomScale);
            
            // layout scrollView]
            scrollView.contentSize = self.currentSketchView.bounds.size;
            scrollView.minimumZoomScale = zoomScale;
            scrollView.maximumZoomScale = zoomScale;
            if (ZOOM_ENABLED){
                scrollView.maximumZoomScale = zoomScale*4;    
            }

            [scrollView setZoomScale:zoomScale animated:TRUE];
            [scrollView setContentOffset:CGPointMake(0, 0) animated:TRUE];
            
        }
        
        joystickView.center = CGPointMake(70, 838);
        
    }else{
        if ([self isEditingWO]){
            if (keepOrientationForWO){
                CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
                self.currentSketchView.transform = transform;
                //NOTE: Do not use UIVIew.frame after setting transform. It is undefined
            }else{
                
            }
            
            //zoomScale = SCREEN_HEIGHT/SCREEN_WIDTH; //NSLog(@"zoomScale = %f", zoomScale);
            zoomScale = SCREEN_HEIGHT/1210.0;
            
            
            // init scrollView
            scrollView.contentSize = self.currentSketchView.bounds.size;

            viewOptionButtonsShirt.frame = CGRectMake(0, 380, 200, 140);
            viewOptionButtonsPants.frame = CGRectMake(0, 295, 200, 220);
            viewOptionButtonsJacket.frame = CGRectMake(0, 266, 410, 370);
            
        }else{
            //zoomScale = 615.0/655.0; //this fits the height
            zoomScale = SCREEN_HEIGHT/1210.0; //this fits the width
            
            // init scrollView
            scrollView.contentSize = self.currentSketchView.bounds.size;
        }
        
        scrollView.minimumZoomScale = zoomScale;
        scrollView.maximumZoomScale = zoomScale * (ZOOM_ENABLED?4:1);
        
        [scrollView setZoomScale:zoomScale animated:TRUE];
        [scrollView setContentOffset:CGPointMake(0, 0) animated:TRUE];
        
        joystickView.center = CGPointMake(70, 579);
        
    }
    //NSLog(@"zoomScale = %f", zoomScale);
    
    [self layoutClothsView];
    //[self zoomAccordingToSliderZoom];
    */
    
    
    [joystickView resetJoystick];
    
    if (self.shouldShowJoystick) {
        [workOrderView addSubview:joystickView];
    }else{
        [joystickView removeFromSuperview];
    }
    
    [self autoHideJoystick];
    
    
    for (UIGestureRecognizer* recognizer in [scrollView gestureRecognizers]) {
        //[scrollView removeGestureRecognizer:recognizer];
        //if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        //  [recognizer setEnabled:NO];
        //}
        [recognizer setEnabled:NO];
    }
    
    // Reset this here to test if affects blurring
    scrollView.frame = CGRectMake(0, 50, 1024, 1024);
    
    // DEBUG:
    //NSLog(@"fabricsView.alpha = %f", fabricsView.alpha);
    //NSLog(@"fabricsView.transform = %@", NSStringFromCGAffineTransform(fabricsView.transform));
    //NSLog(@"fabricsView.frame = %@", fabricsView.frame);
    //NSLog(@"fabricsView.center = %@", fabricsView.center);
    //NSLog(@"fabricsView.bounds = %@", fabricsView.bounds);
    
    //NSLog(@"AFTER: sketchViewWO.frame=%@", NSStringFromCGRect(sketchViewWO.frame));
    //NSLog(@"AFTER: sketchViewCS.frame=%@", NSStringFromCGRect(sketchViewCS.frame));
    //NSLog(@"AFTER: sketchViewCS.bounds=%@", NSStringFromCGRect(sketchViewCS.bounds));
}

/*
- (void)layoutClothsViewAnimated:(BOOL)animated{
    if (animated){
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutClothsView];
        } completion:^(BOOL finished) {
            //do nothing
        }];
    }else{
        [self layoutClothsView];
    }
}
- (void)layoutClothsView{
    
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)){
        if ([self isEditingWO]){
            fabricsView.alpha = 1;
            fabricsView.frame = CGRectMake(0, 911, SCREEN_WIDTH, FabricViewHeight);
        }else{
            if (isShowingClothsView){
                fabricsView.alpha = 1;
                if (isShowingKeyboard){
                    fabricsView.frame = CGRectMake(0, SCREEN_HEIGHT-20-49-44-FabricViewHeight+2-264, SCREEN_WIDTH, FabricViewHeight);
                }else{
                    fabricsView.frame = CGRectMake(0, SCREEN_HEIGHT-20-49-44-FabricViewHeight+2, SCREEN_WIDTH, FabricViewHeight);
                }
            }else{
                fabricsView.alpha = 0;
                fabricsView.frame = CGRectMake(0, SCREEN_HEIGHT-20-49-44+2, SCREEN_WIDTH, FabricViewHeight); //this hides it
            }
        }
    }else{
        if ([self isEditingWO]){
            fabricsView.alpha = 0;
            fabricsView.frame = CGRectMake(0, 655, SCREEN_HEIGHT, FabricViewHeight);
        }else {
            if (isShowingClothsView){
                fabricsView.alpha = 1;
                if (isShowingKeyboard){
                    fabricsView.frame = CGRectMake((SCREEN_HEIGHT-SCREEN_WIDTH)/2, 0, SCREEN_WIDTH, FabricViewHeight);
                }else{
                    fabricsView.frame = CGRectMake((SCREEN_HEIGHT-SCREEN_WIDTH)/2, SCREEN_WIDTH-20-49-44-FabricViewHeight+2, SCREEN_WIDTH, FabricViewHeight);
                }
            }else{
                fabricsView.alpha = 0;
                fabricsView.frame = CGRectMake((SCREEN_HEIGHT-SCREEN_WIDTH)/2, SCREEN_WIDTH-20-49-44+2, SCREEN_WIDTH, FabricViewHeight); //this hides it
            }
        }
    }
    
}

- (void)showMeasurementPanel2{
    
    //Boolean isPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    Boolean isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    
    NSLog(@"isPortrait=%@", (isPortrait?@"YES":@"NO"));
    
    
    if (measurementPanel2Controller == nil){
        measurementPanel2Controller = [[MeasurementPanel2Controller alloc] init];
        measurementPanel2Controller.delegate = self;
        measurementPanel2Controller.workorder = self.workorder;
    }
    [workOrderView addSubview:measurementPanel2Controller.view];
    //measurementPanel2Controller.view.frame = CGRectMake(0, 44, SCREEN_WIDTH, 911);
    measurementPanel2Controller.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, 911);
    [self hideSketchToolBar];
    [measurementPanel2Controller showViews];
    
}
*/





#pragma mark - Custom Popovers

- (void)showPenOptionsFromButton:(UIButton*)button{
    
    if (mainPopoverController != Nil){
        [mainPopoverController dismissPopoverAnimated:YES];
        mainPopoverController = Nil;
    }
    
    RYTPenOptionsViewController *penOptionsViewCtr = [[RYTPenOptionsViewController alloc]init];
    penOptionsViewCtr.sketchView = self.currentSketchView;
    penOptionsViewCtr.sketchViewController = self;
    mainPopoverController = [[UIPopoverController alloc]initWithContentViewController:penOptionsViewCtr];
    
    CGRect showRect = CGRectMake(button.frame.origin.x, button.frame.origin.y+35, button.frame.size.width, button.frame.size.height);
    [mainPopoverController presentPopoverFromRect:showRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}




#pragma mark - Custom Methods

// TODO: Refactor into sketchWill_____ and sketchDid____ methods.

- (void)zoomAccordingToSliderZoom{
    scrollView.zoomScale = ((scrollView.maximumZoomScale-scrollView.minimumZoomScale) * sliderZoom.value) + scrollView.minimumZoomScale;
    [scrollView flashScrollIndicators];
}

//TODO: This function is similar to didInitSketchForClothset, consider refactor
- (void)didInitSketchWithMeasureTemplateAnimated:(BOOL)animated{
    NSLog(@"didInitSketchWithMeasureTemplateAnimated");
    
    // Show sketch view
    if (animated){
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            //sketchViewWO.alpha = 1;
            theSketchView.alpha = 1;
        } completion:^(BOOL finished) {
            ///do nothing
        }];
    }else{
        theSketchView.alpha = 1;
    }
}

- (void)initSketchForClothset:(NSUInteger)clothsetIndex animated:(BOOL)animated{
    NSLog(@"initSketchForClothset:animated:");
    
    if (animated){
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutSubviewsCustom];
        } completion:^(BOOL finished) {
            //do nothing
        }];
    }else{
        [self layoutSubviewsCustom];
    }
    
    // Initialize template
    
    /*
    NSString *templateName;
    NSString *templateCategory;
    
    
    Workorder *wo = [DataManager currentWorkorder];
    templateCategory = wo.templateCategory;

    Clothset *cs;
    cs = [wo.sortedClothsets objectAtIndex:clothsetIndex];    
    
    templateName = cs.templateID;
    
    NSDictionary *templateInfo = [[DataManager instance]getTemplateInfo:templateName templateCategory:templateCategory];
    NSString *templatePath = [templateInfo objectForKey:@"template_filename"];
    //templatePath = [[NSString alloc] initWithFormat:@"%@%@", @"Templates/", templatePath];
    NSLog(@"templatePath=%@",templatePath);
    
    UIImage *img = [UIImage imageNamed:templatePath];
    //img = [self resizeImage:img newSize:sketchView.bounds.size];
    
    [theSketchView setTemplate:img];
    */
    
    // TODO: If we want a underlay
    //[theSketchView setTemplate:img];
    
    
    // Initialize sketch
    
    /*
    NSString *pathToSketch = [RYTSketchViewUtils getFilePathForClothset:cs];
    //NSLog(@"Trying to load sketch from %@",pathToSketch);
    
    NSData *sketchData = [NSData dataWithContentsOfFile:pathToSketch];
    UIImage *sketch;
    //sketch = [UIImage imageWithContentsOfFile:pathToSketch];
    sketch = [UIImage imageWithData:sketchData];
    
    [theSketchView initWithUIImage:sketch];
    */
    
    // TODO: If we want to load a previous sketch
    //[theSketchView initWithUIImage:sketch];

    [self didInitSketchForClothset:clothsetIndex animated:animated];
}

//TODO: This function is similar to didInitSketchWithMeasureTemplateAnimated, consider refactor
- (void)didInitSketchForClothset:(NSUInteger)clothsetIndex animated:(BOOL)animated{
    NSLog(@"didInitSketchForClothset:animated:");
    
    // Show sketch view
    if (animated){
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            theSketchView.alpha = 1;
        } completion:^(BOOL finished) {
            ///do nothing
        }];
    }else{
        theSketchView.alpha = 1;
    }
    
}



- (void)saveMeasureSketchOnComplete:(void (^)(void))onComplete{
    NSLog(@"SketchViewController.saveMeasureSketchOnComplete");
    
    if (!theSketchView.modified){
        onComplete();
        return;
    }
    
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.labelText = @"Saving...";
    hud.removeFromSuperViewOnHide = YES;
    [self.view addSubview:hud];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        hud.alpha = 1.0;
    } completion:^(BOOL finished) {
        
        // TODO: Think of how ot let them save easily
        //[RYTSketchViewUtils writeSketchForContents:[theSketchView getUIImage]];
        theSketchView.modified = FALSE;
        
        NSLog(@"\tdidSaveMeasureSketch");
        onComplete();
        //[[DataManager instance] saveWorkorder];
        [hud hide:YES];
    }];
    
}

- (void)saveClothsetSketchOnComplete:(void (^)(void))onComplete{
    NSLog(@"SketchViewController.saveClothsetSketchOnComplete");
    
    if (!theSketchView.modified){
        onComplete();
        return;
    }
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.labelText = @"Saving...";
    hud.removeFromSuperViewOnHide = YES;
    [self.view addSubview:hud];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        hud.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (theSketchView.modified){
            //[RYTSketchViewUtils writeSketchForContents:[theSketchView getUIImage]];
            theSketchView.modified = FALSE;
            
            NSLog(@"\tUpdating thumbnail");
            //[RYTSketchViewUtils writeThumbnailForClothset:[DataManager currentClothset] contents:[theSketchView getThumbnail]];
            
            NSLog(@"\tdidSaveClothsetSketch");
        }
        onComplete();
        //[[DataManager instance] saveWorkorder];
        [hud hide:YES];
    }];
}

- (void)saveChangesBeforeExit{
    NSLog(@"saveChangesBeforeExit");
    //[self saveChangesBeforeSwitchEditMode];
    
    //TODO: only save cloths if were editing cloths
    if (![self isEditingWO]){
        [self saveClothsetSketchOnComplete:^(void) {
            NSLog(@"\tblock passed into hideWaitAnimated after didSaveClothsetSketch");
            [self didSaveChangesBeforeExit];
        }];
    }else{
        [self saveMeasureSketchOnComplete:^(void) {
            NSLog(@"\tblock passed into hideWaitAnimated after didSaveMeasureSketch");
            [self didSaveChangesBeforeExit];
        }];

    }
    //[[DataManager instance] saveWorkorder];
}

//TODO: This is similar to initUIForClothset:animated:, consider refactor
- (void)initUIForWorkorderEditAnimated:(BOOL)animated{
    NSLog(@"initUIForWorkorderEditAnimated:");

    [self initSketchWithMeasureTemplateAnimated:animated];
    
    //Always hide
    btnSetOptions.alpha = 0;
    btnSetOptions.center = CGPointMake(btnSetOptions.center.x, 6);
    
    if (animated){
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            theSketchView.alpha = 1;
            
        } completion:^(BOOL finished) {
            
        }];
    }else{
        
        theSketchView.alpha = 1;

    }
    
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    // Flip to human-friendly orientation.
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    CGContextConcatCTM(context, flipVertical);
    
    // Draw into the context. This does the actual scaling.
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();    
    
    return newImage;
}

/*
- (void)willSwitchEditMode{
    [self saveChangesBeforeSwitchEditMode];
}

- (void)saveChangesBeforeSwitchEditMode{
    
    //[[DataManager instance] saveWorkorder];

    if (previousSetSelectorIndex == 0){
        //going from Measure to Clothset
        [self saveMeasureSketchOnComplete:^(void) {
            [self didSaveChangesBeforeSwitchingEditMode];
        }];
    }else{
        [self saveClothsetSketchOnComplete:^(void) {
            [self didSaveChangesBeforeSwitchingEditMode];
        }];
        
    }
}
*/

// Called when saving operations are done
- (void)didSaveChangesBeforeSwitchingEditMode{
    NSLog(@"didSaveChangesBeforeSwitchingEditMode");
    
    /*
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        theSketchView.alpha = 0;
        viewOptionButtonsShirt.alpha = 0;
        viewOptionButtonsPants.alpha = 0;
        viewOptionButtonsJacket.alpha = 0;

    } completion:^(BOOL finished) {
        
        if (btnSetSelector2.selectedSegmentIndex == 0){
            //selected work order
            [self initUIForWorkorderEditAnimated:YES];
        }else{
            //selected a clothset
            [self initUIForClothset:self.currentClothsetIndex animated:YES];
        }
        
        btnSetSelector2.enabled = TRUE;

    }];*/

}

- (void)didSaveChangesBeforeExit{
    NSLog(@"didSaveChangesBeforeExit");
}

- (void)autoHideJoystick{
    if ((scrollView.contentSize.width > (scrollView.frame.size.width+10)) || (scrollView.contentSize.height > (scrollView.frame.size.height+10))){
        joystickView.alpha=1;
    }else{
        joystickView.alpha = 0.3;
    }
}

- (void)clearSketch{
    
    NSString *message = @"Are you sure you want to clear the sketch?";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:
                          @"Clear sketch" message:message delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Clear", nil];
    alert.tag = 2;
    [alert show];
}

-(void)keyboardWillShow:(NSNotification *)n{
    //NSLog(@"keyboardWillShow, isShowingKeyboard=%@", (isShowingKeyboard?@"YES":@"NO"));
    if (isShowingKeyboard){
        return;
    }
    
    isShowingKeyboard = TRUE;
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    //NSLog(@"keyboardSize=%@", NSStringFromCGSize(keyboardSize));
    //keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //NSLog(@"keyboardSize(End)=%@", NSStringFromCGSize(keyboardSize));
    
    UIEdgeInsets e = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])){
        e = UIEdgeInsetsMake(0, 0, keyboardSize.width, 0);
    }
    
    //[clothsViewController offSetForKeyboard:e];
    //[self layoutClothsViewAnimated:YES];
}

-(void)keyboardWillHide:(NSNotification *)n{
    //NSLog(@"keyboardWillHide, isShowingKeyboard=%@", (isShowingKeyboard?@"YES":@"NO"));
    
    isShowingKeyboard = FALSE;
    
    //UIEdgeInsets e = UIEdgeInsetsMake(0, 0, 0, 0);
    //[clothsViewController offSetForKeyboard:e];
    //[self layoutClothsViewAnimated:YES];
}














#pragma mark - Custom - Clothset Related

/*
- (void)addNewClothset{
    
    if ([DataManager currentWorkorder].clothsets.count < 5){
        [self showTemplateSelectorByTemplateCategory:self.workorder.templateCategory withSelectMode:1];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already have 5 Sets" message:@"A workorder can only hold 5 sets." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void)addNewClothsetWithTemplateName:(NSString*)templateName{
    
    BOOL result = [DataManager addNewClothsetWithTemplateName:templateName];
    if (result){
        
        NSUInteger newSetIndex = self.workorder.clothsets.count;
        NSString *newTitle = [NSString stringWithFormat:@"Set %lu", (unsigned long)newSetIndex];
        //[btnSetSelector insertSegmentWithTitle:newTitle atIndex:btnSetSelector.numberOfSegments animated:YES];
        [btnSetSelector2 insertSegmentWithTitle:newTitle atIndex:btnSetSelector2.numberOfSegments animated:YES];
        [btnSetSelector2 relabelSets];
        
        [self resizeSetSelector];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not create new set. Please restart the app and try again, or contact your system Administrator." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)willDeleteClothset{
    UIAlertView *alert;
    
    if (self.workorder.clothsets.count > 1){
        
        NSString *message = @"Are you sure you want to delete this clothset? This action is not undoable.";
        alert = [[UIAlertView alloc] initWithTitle:
                 @"Delete Clothset" message:message delegate:self
                                 cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        alert.tag = 3;
    }else{
        
        alert = [[UIAlertView alloc] initWithTitle:
                 @"No Clothset to delete" message:@"You cannot delete the only clothset in the workorder." delegate:self
                                 cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
    
    [alert show];
}

- (void)deleteClothset{
    NSUInteger prevSegmentIndex = btnSetSelector2.selectedSegmentIndex;
    if (self.workorder.clothsets.count > 1){
        
        //[[DataManager instance]saveWorkorder];
        //[self.workorder removeClothsetByLocalID:[DataManager.currentClothset.localID integerValue]];
        [self.workorder removeClothsetByIndex:btnSetSelector2.selectedSegmentIndex-1];
        [[DataManager instance]saveWorkorder];
        
        NSInteger nextSelectedIndex = 0;
        if (prevSegmentIndex-1 > 0){
            nextSelectedIndex = prevSegmentIndex-1;
        }else{
            nextSelectedIndex = 1;
        }
        //btnSetSelector2.selectedSegmentIndex = nextSelectedIndex;
        
        [btnSetSelector2 removeSegmentAtIndex:btnSetSelector2.selectedSegmentIndex nextSelectedIndex:nextSelectedIndex animated:YES];
        self.currentSetSelectorIndex = nextSelectedIndex;
        //[self relabelSetsInSetSelector];
        
        [self willSwitchEditMode];
    }
}

- (void)willDuplicateClothset{
    if (self.workorder.clothsets.count >= 5){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already have 5 Sets" message:@"A workorder can only hold 5 sets." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    UIAlertView *alert;
    
    NSString *message = @"Are you sure you want to duplicate this clothset? This action is not undoable.";
    alert = [[UIAlertView alloc] initWithTitle:
             @"Duplicate Clothset" message:message delegate:self
                             cancelButtonTitle:@"Cancel" otherButtonTitles:@"Duplicate", nil];
    alert.tag = 4;
    [alert show];
}


- (void)duplicateClothset{
    
}

*/






















#pragma mark - Custom - SetSelector Related

/*
- (void)initSetSelectorAnimated:(BOOL)animated{
    NSLog(@"SketchViewController.initSetSelectorAnimated");
    
    NSString *title;
    
    [btnSetSelector2 removeAllSegments];
    [btnSetSelector2 insertSegmentWithTitle:@"Measure" atIndex:0 animated:NO];
    
    int setIndex = 0;
    for (Clothset *clothset in self.workorder.sortedClothsets) {
        setIndex++;
        //title = [NSString stringWithFormat:@"Set %@", clothset.localID];
        title = [NSString stringWithFormat:@"Set %d", setIndex];
        [btnSetSelector2 insertSegmentWithTitle:title atIndex:btnSetSelector2.numberOfSegments animated:animated];
    }
    
    //Resize segments
    [btnSetSelector2 resizeAccordingly];
    
    //Select measurements tab by default
    [btnSetSelector2 setSelectedSegmentIndex:0];
    self.currentSetSelectorIndex = 0;
}

- (void)resizeSetSelector{
    [btnSetSelector2 resizeAccordingly];
}

- (void)relabelSetsInSetSelector{
    
    for (int i=1; i<btnSetSelector2.numberOfSegments; i++) {
        [btnSetSelector2 setTitle:[NSString stringWithFormat:@"Set %d", i] forSegmentAtIndex:i];
    }
}
 
*/


















#pragma mark - SketchViewDelegate

- (void)handlePan:(UIPanGestureRecognizer *)recognizer translation:(CGPoint)translation{
    //NSLog(@"SketchViewController.handlePan, translation=%@", NSStringFromCGPoint(translation));
    //scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x+translation.x, scrollView.contentOffset.y+translation.y);
    
    if (recognizer.state == UIGestureRecognizerStateBegan){
        startPanLocaton = translation;
    }else if (recognizer.state == UIGestureRecognizerStateEnded){
    }else{
        scrollView.contentOffset = CGPointMake(-translation.x, -translation.y);
    }
}

- (void)handlePan:(CGPoint)p1 and:(CGPoint)p2 phase:(NSInteger)phase{
    
    CGFloat centerX = (abs(p1.x+p2.x))/2;
    CGFloat centerY = (abs(p1.y+p2.y))/2;
    CGPoint center = CGPointMake(centerX, centerY);
    
    if (phase == 1){
        //startPanDist = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
        //startZoomScale = scrollView.zoomScale;
        startPanLocaton = center;
        //NSLog(@"\tstartPanLocaton=%@", NSStringFromCGPoint(startPanLocaton));
        startContentOffset = scrollView.contentOffset;
        //NSLog(@"\tstartContentOffset=%@", NSStringFromCGPoint(startContentOffset));
    }else if (phase == 2){
        //CGFloat currDist = ((p2.x-p1.x)*(p2.x-p1.x))+((p2.y-p1.y)*(p2.y-p1.y));
        //CGFloat scaleDelta = sqrt(currDist/startPanDist);
        //scrollView.zoomScale = startZoomScale * scaleDelta;
        
        CGFloat targetOffsetX = startPanLocaton.x-center.x+startContentOffset.x;
        CGFloat targetOffsetY = startPanLocaton.y-center.y+startContentOffset.y;
        //NSLog(@"\ttargetOffset=%@", NSStringFromCGPoint(CGPointMake(targetOffsetX, targetOffsetY)));
            
        //Prevent from moving off screen
        if (targetOffsetX > (scrollView.contentSize.width - SketchViewMinBorderForPan)){
            targetOffsetX = scrollView.contentSize.width - SketchViewMinBorderForPan;
        }else if (targetOffsetX < -self.view.frame.size.width + SketchViewMinBorderForPan) {
            targetOffsetX = -self.view.frame.size.width + SketchViewMinBorderForPan;
        }
            
        if (targetOffsetY > (scrollView.contentSize.height-SketchViewMinBorderForPan)){
            targetOffsetY = scrollView.contentSize.height-SketchViewMinBorderForPan;
        }else if (targetOffsetY < -self.view.frame.size.height + SketchViewMinBorderForPan) {
            targetOffsetY = -self.view.frame.size.height + SketchViewMinBorderForPan;
        }
        scrollView.contentOffset = CGPointMake(targetOffsetX, targetOffsetY);
        //NSLog(@"\tscrollView.contentOffset=%@", NSStringFromCGPoint(scrollView.contentOffset));
    }
    
    
    
}

- (UIView *)viewForTouch{
    //return scrollView;
    return self.view;
}












































#pragma mark - UIAlertView handlers

// save if 'save' is selected from the alertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 2){
        if (buttonIndex == 1){
            [self.currentSketchView clearSketch];
        }
    }else if(alertView.tag == 3){
        if (buttonIndex == 1){
            [self deleteClothset];
        }
    }else if(alertView.tag == 3){
        if (buttonIndex == 1){
            [self duplicateClothset];
        }
    }
}























#pragma mark - ScrollView Functions

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.currentSketchView;
}

- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
    NSLog(@"centeredFrameForScrollView");
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
    //sketchView.frame = [self centeredFrameForScrollView:scrollView andUIView:sketchView];
    [self autoHideJoystick];
}
























// Protocol Metohds

#pragma mark - CustomerSelectorDelegate Methods

/*
- (void)customerSelector:(CustomerSelectorBaseController *)customerSelector customerSelected:(NSDictionary *)customer {
    
    selectedCustomerName = customer[@"DisplayName"];
    selectedCustomer = customer;
    NSLog(@"SketchViewController.customerSelected:, selectedCustomer=%@",selectedCustomer);
    
    if (customerSelector.isFirstStep){
        // Dismiss this and show template Selector
        [self dismissModalViewControllerAnimated:YES];
        [self waitAndShowTemplateSelector];
    }else{
        [self dismissModalViewControllerAnimated:YES];
        [self setCustomer:customer];
    }

}

- (void)customerSelector:(CustomerSelectorBaseController *)customerSelector cancelledAnimated:(BOOL)aniamted {
    [self dismissModalViewControllerAnimated:YES];
    
    if (customerSelector.isFirstStep){
        //this is a newWorkorder, if customer is not selected, we cannot proceed.
        [APP_DELEGATE gotoWorkordersTab];
    }
}

*/


















#pragma mark - TemplatesSelectorDelegate Methods
/*
- (void)templateSelected:(NSString *)templateName templateCategory:(NSString *)templateCategory selectMode:(int)selectMode{
    [self dismissModalViewControllerAnimated:YES];
    
    switch (selectMode) {
        case 0:{
            // creating new workorder
            Workorder *newWorkorder;
            
            if (selectedCustomerName != nil){
                newWorkorder = [[DataManager instance] newWorkorderWithTemplate:templateName templateCategory:templateCategory customer:selectedCustomer];
                [[DataManager instance] saveWorkorder];
                [[DataManager instance] loadWorkorder:newWorkorder];
                
                [self.workorderSplitViewController setCurrentIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                
            }else if (newWOOptions_workorderID != 0){
                //TODO: Handle the response from editRemoteTempWO to properly get the customer data
                
                EditRemoteWorkorderController *editRemoteWOController = [[EditRemoteWorkorderController alloc]init];
                editRemoteWOController.delegate = self;
                editRemoteWOController.remoteWorkorderID = newWOOptions_workorderID;
                editRemoteWOController.templateCategory = templateCategory;
                editRemoteWOController.templateName = templateName;
                
                [self waitAndShowEditRemoteWorkorderDialog:editRemoteWOController];
                
            }else {
                newWorkorder = [[DataManager instance] newWorkorderWithTemplate:templateName templateCategory:templateCategory customer:nil];
                [[DataManager instance] saveWorkorder];
                [[DataManager instance] loadWorkorder:newWorkorder];

                [self.workorderSplitViewController setCurrentIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                
            }
            [self loadWorkorder:newWorkorder];
        }
            break;
            
        case 1:
            // creating new clothset
            [self addNewClothsetWithTemplateName:templateName];
            break;
            
        default:
            break;
    }
}
*/

#pragma mark - RYTSketchViewControllerDelegate

- (RYTSketchView *)sketchView {
    return self.currentSketchView;
}

/*
- (void)showCustomerSelectorAsFirstStep:(BOOL)asFirstStep{
    NSLog(@"SketchViewController.showCustomerSelectorAsFirstStep: asFirstStep=%@", (asFirstStep?@"Yes":@"No"));
    
    CustomerSelectorController *customerSelector = [[CustomerSelectorController alloc] init];
    customerSelector.delegate = self;
    
    if (asFirstStep){
        customerSelector.isFirstStep = TRUE;
    }else{
        NSString *isNew = self.workorder.customerRoleID ? @"Existing" : @"New";
        NSDictionary *customer = [NSDictionary dictionaryWithObjectsAndKeys:self.workorder.customer, @"DisplayName", self.workorder.customerContact, @"Mobile", self.workorder.customerEmail, @"Email1", self.workorder.remarks, @"Remarks", isNew, @"isNew", nil];
        
        [customerSelector initWithOfflineCustomer:customer];
    }
    
    UINavigationController *customerSelectorNavigationController = [[UINavigationController alloc] initWithRootViewController:customerSelector];
    customerSelectorNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    customerSelectorNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:customerSelectorNavigationController animated:YES];
    
}

- (void)showTemplateSelector{
    
    TemplateSelectorLevel1Controller *templateSelector = [[TemplateSelectorLevel1Controller alloc] initWithStyle:UITableViewStylePlain];
    templateSelector.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:templateSelector];
    
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:navigationController animated:YES];
}

- (void)waitAndShowTemplateSelector{
    
    if (self.modalViewController) {
        NSLog(@"Wait another 0.1 (waitAndShowTemplateSelector)");
        [self performSelector:@selector(waitAndShowTemplateSelector)
                   withObject:nil 
                   afterDelay:0.1f];
        return;
    }
    NSLog(@"Ready to show templateSelector!");
    
    [self showTemplateSelector];
}

- (void)pushTemplateSelectorToModalNav{
    
    if ([self.modalViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *theNavCtrl = (UINavigationController*)self.modalViewController;
        TemplateSelectorLevel1Controller *rootViewController = [[TemplateSelectorLevel1Controller alloc] initWithStyle:UITableViewStylePlain];
        rootViewController.delegate = self;
        
        //[theNavCtrl popToRootViewControllerAnimated:NO];
        [theNavCtrl pushViewController:rootViewController animated:YES];
    }
    
    
}

- (void)showTemplateSelectorByTemplateCategory:(NSString*)templateCategory withSelectMode:(NSUInteger)selectMode{
    
    
    //Setup new controller
    TemplateSelectorLevel2Controller *level2ViewController = [[TemplateSelectorLevel2Controller alloc] initWithStyle:UITableViewStylePlain];
    level2ViewController.delegate = self;
    level2ViewController.navigationItem.title = [NSString stringWithFormat:@"Choose a template (%@^:",templateCategory];
    level2ViewController.templateCateogry = templateCategory;
    level2ViewController.templateSelectMode = selectMode;

    
    level2ViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    level2ViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    
    //[self presentModalViewController:level2ViewController animated:YES];
    
    UINavigationController *navCtrl = [[UINavigationController alloc]initWithRootViewController:level2ViewController];
    navCtrl.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:navCtrl animated:YES];
}

- (void)waitAndShowEditRemoteWorkorderDialog:(EditRemoteWorkorderController*)editRemoteWorkorderController{
    
    if (self.modalViewController) {
        NSLog(@"Wait another 0.1 (waitAndShowEditRemoteWorkorderDialog)");
        [self performSelector:@selector(waitAndShowEditRemoteWorkorderDialog:)
                   withObject:editRemoteWorkorderController 
                   afterDelay:0.1f];
        return;
    }
    NSLog(@"Ready to show editRemoteWorkorderController!");
    
    [self presentModalViewController:editRemoteWorkorderController animated:YES];
}
*/


- (void)dismissAllPopovers {
    
    /*
    if (self.sketchOptionsPanelPopover != nil){
        [self.sketchOptionsPanelPopover dismissPopoverAnimated:YES];
        self.sketchOptionsPanelPopover = Nil;
    }
    
    if (self.workorderInfoPanelPopover != nil){
        [self.workorderInfoPanelPopover dismissPopoverAnimated:YES];
        self.workorderInfoPanelPopover = Nil;
    }
    */
    
    if (mainPopoverController != Nil){
        [mainPopoverController dismissPopoverAnimated:YES];
        mainPopoverController = Nil;
    }
}

// Hides sketch toolbar
- (void)hideSketchToolBar{
    if (self.toolbarIsHidden){
        return;
    }
    [UIView animateWithDuration:0.3 
                          delay:0.0 
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.viewSketchTools.alpha = 0;
                         
                         self.currentSketchView.center = CGPointMake(self.currentSketchView.center.x, self.currentSketchView.center.y - 42);
                         
                     }
                     completion:^(BOOL finished){
                     }
     ];
    toolbarIsHidden = TRUE;
    
}

// Shows sketch toolbar
- (void)showSketchToolBar{
    if (!self.toolbarIsHidden){
        return;
    }
    [UIView animateWithDuration:0.3 
                          delay:0.0 
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.viewSketchTools.alpha = 1;
                         
                         self.currentSketchView.center = CGPointMake(self.currentSketchView.center.x, self.currentSketchView.center.y + 42);
                     }
                     completion:^(BOOL finished){
                     }
     ];
    toolbarIsHidden = FALSE;
}

/*
- (void)dismissMeasurementPanel2{
    if (measurementPanel2Controller){
        [self reloadOptionButtons];
        
        [measurementPanel2Controller hideViewsAnimated:YES completion: ^(BOOL finished) {
            [measurementPanel2Controller.view removeFromSuperview];
            [self showSketchToolBar];
        }];
    }
}
*/

- (void)setUndoButtonEnabled:(BOOL)undoEnabled redoButtonEnabled:(BOOL)redoEnabled{
    //NSLog(@"SketchViewController.setUndoButtonEnabled:%@ redoButtonEnabled:%@",(undoEnabled?@"YES":@"NO"),(redoEnabled?@"YES":@"NO"));
    btnUndo.enabled = undoEnabled;
    btnRedo.enabled = redoEnabled;
}

- (void)zoomInToPoint:(CGPoint)point{
    //TODO: Set proper contentOffset
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (scrollView.zoomScale > 1){
            scrollView.contentOffset = CGPointZero;
            scrollView.zoomScale = 1;
        }else{
            
            //CGRect contentFrame = self.currentSketchView.frame;
            CGRect bounds = self.view.bounds;
            CGFloat newZoom = scrollView.maximumZoomScale;
            
            //NSLog(@"contentFrame=%@, bounds=%@", NSStringFromCGRect(contentFrame), NSStringFromCGRect(bounds));
            
            //scrollView.contentOffset = CGPointMake((point.x * newZoom) - (bounds.size.width/2), (point.y * newZoom) - (bounds.size.height/2));
            //scrollView.contentOffset = CGPointMake(50, 50);
            //scrollView.contentOffset = CGPointMake(point.x/newZoom, point.y/newZoom);
            scrollView.contentOffset = CGPointMake((point.x) - (bounds.size.width/2), (point.y) - (bounds.size.height/2));
            //NSLog(@"new offset = %@", NSStringFromCGPoint(scrollView.contentOffset));
            scrollView.zoomScale = newZoom;
        }
    } completion:^(BOOL finished) {
        //do nothing
    }];
    
}



















#pragma mark - JoystickViewControllerDelegate

- (void)joystick:(RYTJoystickView *)joystick moved:(CGPoint)delta{
    
    if (scrollView.zoomScale == 1.0){
        //ignore
        return;
    }
    
    
    CGPoint offset;
    if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])){
        if ((scrollView.contentSize.width < SCREEN_WIDTH) || (scrollView.contentSize.height < 861)){
            //ignore
            return;
        }
        offset = CGPointMake(delta.x * (scrollView.contentSize.width-SCREEN_WIDTH), delta.y * (scrollView.contentSize.height-861));
    }else {
        if ((scrollView.contentSize.width < SCREEN_HEIGHT) || (scrollView.contentSize.height < 605)){
            //ignore
            return;
        }
        offset = CGPointMake(delta.x * (scrollView.contentSize.width-SCREEN_HEIGHT), delta.y * (scrollView.contentSize.height-605));
    }
    NSLog(@"offset=%@", NSStringFromCGPoint(offset));
    scrollView.contentOffset = offset;
}


























// @TODO: deprecate
//- (IBAction)toggleShowControlPoints:(id)sender {
//[sketchView toggleShowControlPoints];
//}



@end
