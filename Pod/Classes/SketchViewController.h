//
//  SketchViewController.h
//  RYTSketchView
//
//  Created by Ryan Tan on 9/12/11.
//  Copyright 2011 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "DataManager.h"

#import "RYTSketchView.h"
//#import "WorkOrderInfoPanelController.h"
//#import "TemplateSelectorLevel1Controller.h"

//#import "CustomerPanelController.h"
//#import "CustomerSelectorController.h"
//#import "CustomerSelectorController2.h"
//#import "SketchOptionsPanelController.h"
//#import "MeasurementPanel2Controller.h"
//#import "CustomSegmentedControl.h"

//Delegates
#import "RYTSketchViewControllerDelegate.h"
#import "RYTJoystickViewDelegate.h"

//@class SketchView;
@class SketchHistoryViewSmall;
//@class WorkOrderInfoPanelController;
//@class ClothsetClothsViewController;
//@class ClothsetInfoViewController;
//@class EditRemoteWorkorderController;

@interface SketchViewController : UIViewController <
    UIPopoverControllerDelegate,
    RYTSketchViewDelegate,
    UIScrollViewDelegate,
    UIAlertViewDelegate,
    RYTJoystickViewDelegate,
    RYTSketchViewControllerDelegate
> {
    
    RYTSketchView *theSketchView;
    __unsafe_unretained IBOutlet UIView *workOrderView;
    __weak IBOutlet UIToolbar *toolBarView;
    
    BOOL isShowingKeyboard;
    
    
    //Custom UI elements
    //UIView *fabricsView; // This is a parent container for clothsView
    UIScrollView *scrollView;
    
    RYTJoystickView *joystickView;
    
    //ClothsetClothsViewController *clothsViewController;
    //UIView *clothsView;
    //ClothsetInfoViewController *clothsetInfoViewController;
    //UIView *clothsetInfoView;
    
    //stores which clothset (or measurement tab) is currently selected
    //NSInteger _currentSetSelectorIndex;
    //NSInteger previousSetSelectorIndex;
    //BOOL isShowingClothsView;
    
    //stores selected properties before the workorder is created
    //NSString *selectedCustomerName;
    //NSDictionary *selectedCustomer;
    //NSString *selectedTemplateCategory;
    //NSString *selectedTemplate;
    
    //NSUInteger newWOOptions_workorderID;
    //NSString *newWOOptions_invoiceID;
    //NSUInteger newWOOptions_roleID;
    //NSString *newWOOptions_customerName;
    

    UIAlertView *alertWait;
    UIAlertView *alertWhenSaving;
    
    
    //UIView *waitView;
    //UIView *waitViewDialog;
    //UIActivityIndicatorView *waitViewActivityView;
    
    
    //Touch related
    CGPoint startPanLocaton;
    CGPoint startContentOffset;
    CGFloat startPanDist;
    CGFloat startZoomScale;
    
    
    
    
    // option buttons
    NSMutableArray *optionButtons;
    NSMutableDictionary *optionButtonsTagToKeyMap;
    NSMutableDictionary *optionButtonsKeyToTagMap;
    UIView *viewOptionButtonsShirt;
    UIView *viewOptionButtonsPants;
    UIView *viewOptionButtonsJacket;
    
    //Popovers and panes
    UIPopoverController *mainPopoverController;
                                                        
    
    // Controls
    // TODO: init controls manually in loadView instead of nibs when I have time
    
    // TODO: Change these to a method call. The control in the parent controller should call this method
    //__weak IBOutlet UISegmentedControl *btnSetSelector;
    //CustomSegmentedControl *btnSetSelector2;
    //__weak IBOutlet UIBarButtonItem *btnNewClothset;
                                                        
    
    __weak IBOutlet UIButton *btnPen;
    __weak IBOutlet UIButton *btnPenRed; // This is a special request to have the most-used alternative as a separate control on it's own.
    __weak IBOutlet UIButton *btnEraser;
    //__weak IBOutlet UIButton *btnWOOptions;
    //__weak IBOutlet UIButton *btnMeasure;
    __weak IBOutlet UIButton *btnSetOptions;
    //__weak IBOutlet UIButton *btnFabric;
    __weak IBOutlet UISlider *sliderZoom;
    __weak IBOutlet UIButton *btnCSOptions;
    
    __weak IBOutlet UIButton *btnSave;
    __weak IBOutlet UIButton *btnUndo;
    __weak IBOutlet UIButton *btnRedo;
    //__weak IBOutlet UILabel *lblControlPoints;
    //__weak IBOutlet UISwitch *switchControlPoints;
    
    __weak IBOutlet UIBarButtonItem *btnHideBar;
    //__weak IBOutlet UILabel *lblClothsetID;
    
}

@property (strong, nonatomic) IBOutlet UIView *viewSketchTools;
@property (nonatomic, assign) BOOL toolbarIsHidden;


// IBActions
- (IBAction)btnTemplates:(id)sender;
- (IBAction)saveTapped:(id)sender;
//- (IBAction)hideBarTapped:(id)sender;
- (IBAction)undoTapped:(id)sender;
- (IBAction)redoTapped:(id)sender;
- (IBAction)deleteTapped:(id)sender;
- (IBAction)csOptionsTapped:(id)sender;




// Sketch Tools
- (IBAction)clearSketchTapped:(id)sender;
- (IBAction)penToolSelected:(id)sender;
- (IBAction)penToolSelectedRed:(id)sender;
- (IBAction)eraserToolSelected:(id)sender;
- (IBAction)textToolSelected:(id)sender;
- (IBAction)sliderZoomChanged:(id)sender;



//Custom Status getters
- (RYTSketchView*) currentSketchView;
- (BOOL) isEditingWO;
- (NSUInteger) currentClothsetIndex;


// Custom Laying out
- (void)layoutSubviews;
- (void)layoutSubviewsCustom;
- (void)layoutSubviewsCustomForOrientation:(UIInterfaceOrientation)orientation;
- (void)layoutClothsViewAnimated:(BOOL)animated;
- (void)layoutClothsView;


// Options

@property (nonatomic, assign) BOOL zoomEnabled;
@property (nonatomic, assign) BOOL shouldShowJoystick;


#pragma mark - Custom Popovers
//- (void)showPenOptions;
- (void)showPenOptionsFromButton:(UIButton*)button;
- (void)showClothsetOptions;




#pragma mark - Custom UI Methods
- (void)prepareSketchForAction:(NSString*)sketchAction userInfo:(NSDictionary*)userInfo;
- (void)editRemoteWO:(NSUInteger)workorderID userInfo:(NSDictionary*)userInfo;



//- (void)showMeasurementPanel2;
//- (void)showFabricPanel:(id)sender;
//- (void)showSketchOptionsPanel:(id)sender;
//- (void)showWorkorderInfoPanel:(id)sender;
- (void)zoomAccordingToSliderZoom;
//- (void)loadWorkorder;
//- (void)loadWorkorder:(Workorder *)wo;
//- (void)updateTitleLabelWithCustomerName:(NSString*)customerName workorder:(Workorder*)theWorkorder;


- (void)initSketchWithMeasureTemplateAnimated:(BOOL)animated;
- (void)didInitSketchWithMeasureTemplateAnimated:(BOOL)animated;
- (void)initSketchForClothset:(NSUInteger)clothsetIndex animated:(BOOL)animated;
- (void)didInitSketchForClothset:(NSUInteger)clothsetIndex animated:(BOOL)animated;


// Custom
- (void)saveMeasureSketchOnComplete:(void (^)(void))onComplete;
- (void)saveClothsetSketchOnComplete:(void (^)(void))onComplete;
- (void)saveChangesBeforeExit;
- (void)initUIForWorkorderEditAnimated:(BOOL)animated;
- (void)initUIForClothset:(NSUInteger)clothsetIndex animated:(BOOL)animated;
- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize;
- (void)willSwitchEditMode;
- (void)saveChangesBeforeSwitchEditMode;
- (void)didSaveChangesBeforeSwitchingEditMode;
- (void)didSaveChangesBeforeExit;
- (void)autoHideJoystick;
- (void)clearSketch;
- (BOOL)hasClipboardImage;
- (void)keyboardWillShow:(NSNotification *)n;
- (void)keyboardWillHide:(NSNotification *)n;

// Custom - Clothset
- (void)addNewClothset;
- (void)addNewClothsetWithTemplateName:(NSString*)templateName;
- (void)willDeleteClothset;
- (void)deleteClothset;
- (void)willDuplicateClothset;
- (void)duplicateClothset;


// Custom - SetSelector
- (void)initSetSelectorAnimated:(BOOL)animated;
- (void)resizeSetSelector;
- (void)relabelSetsInSetSelector;

//- (void)waitAndShowEditRemoteWorkorderDialog:(EditRemoteWorkorderController*)editRemoteWorkorderController;


// Touch related








@end
