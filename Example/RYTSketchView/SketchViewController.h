//
//  SketchViewController.h
//  RYTSketchView
//
//  Created by Ryan Tan on 9/12/11.
//  Copyright 2011 Ryan Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "DataManager.h"

#import <RYTSketchView/RYTSketchView.h>
//#import "WorkOrderInfoPanelController.h"
//#import "TemplateSelectorLevel1Controller.h"

//#import "CustomerPanelController.h"
//#import "CustomerSelectorController.h"
//#import "CustomerSelectorController2.h"
//#import "SketchOptionsPanelController.h"
//#import "MeasurementPanel2Controller.h"
//#import "CustomSegmentedControl.h"

//Delegates
//#import "WorkordersSplitViewDelegate.h"
//#import "TemplateSelectorDelegate.h"
#import <RYTSketchView/RYTSketchViewControllerDelegate.h>
#import <RYTSketchView/RYTJoystickView.h>
//#import "EditRemoteWorkorderController.h"

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
    IBOutlet UIToolbar *toolBarView;
    
    BOOL isShowingKeyboard;
    
    
    //Custom UI elements
    UIView *fabricsView; // This is a parent container for clothsView
    UIScrollView *scrollView;
    
    BOOL shouldShowJoystick;
    RYTJoystickView *joystickView;
    
    //ClothsetClothsViewController *clothsViewController;
    //UIView *clothsView;
    //ClothsetInfoViewController *clothsetInfoViewController;
    //UIView *clothsetInfoView;
    
    //stores which clothset (or measurement tab) is currently selected
    NSInteger _currentSetSelectorIndex;
    NSInteger previousSetSelectorIndex;
    BOOL isShowingClothsView;
    
    //stores selected properties before the workorder is created
    NSString *selectedCustomerName;
    NSDictionary *selectedCustomer;
    NSString *selectedTemplateCategory;
    NSString *selectedTemplate;
    
    NSUInteger newWOOptions_workorderID;
    NSString *newWOOptions_invoiceID;
    NSUInteger newWOOptions_roleID;
    NSString *newWOOptions_customerName;
    

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
    
                                                        
                                                        
    //Sketch related
    UIImage *clipboardSketch;
    
    
    // option buttons
    NSMutableArray *optionButtons;
    NSMutableDictionary *optionButtonsTagToKeyMap;
    NSMutableDictionary *optionButtonsKeyToTagMap;
    UIView *viewOptionButtonsShirt;
    UIView *viewOptionButtonsPants;
    UIView *viewOptionButtonsJacket;
    
    //Popovers and panes
    
    //WorkOrderInfoPanelController *_workorderInfoPanel;
    //UIPopoverController *_workorderInfoPanelPopover;
    
    //MeasurementPanel2Controller *measurementPanel2Controller;
    
    //SketchOptionsPanelController *_sketchOptionsPanel;
    //UIPopoverController *_sketchOptionsPanelPopover;
    
    UIPopoverController *mainPopoverController;
                                                        
    
    // Controls
    // TODO: init controls manually in loadView instead of nibs when I have time
    
    // TODO: Change these to a method call. The control in the parent controller should call this method
    //IBOutlet UISegmentedControl *btnSetSelector;
    //CustomSegmentedControl *btnSetSelector2;
    //IBOutlet UIBarButtonItem *btnNewClothset;
                                                        
    
    IBOutlet UIButton *btnPen;
    IBOutlet UIButton *btnPenRed; // This is a special request to have the most-used alternative as a separate control on it's own.
    IBOutlet UIButton *btnEraser;
    IBOutlet UIButton *btnWOOptions;
    IBOutlet UIButton *btnMeasure;
    IBOutlet UIButton *btnSetOptions;
    IBOutlet UIButton *btnFabric;
    IBOutlet UISlider *sliderZoom;
    IBOutlet UIButton *btnCSOptions;
    
    IBOutlet UILabel *lblTitle;
    
    IBOutlet UIButton *btnSave;
    IBOutlet UIButton *btnUndo;
    IBOutlet UIButton *btnRedo;
    IBOutlet UILabel *lblControlPoints;
    IBOutlet UISwitch *switchControlPoints;
    
    IBOutlet UIBarButtonItem *btnHideBar;
    IBOutlet UILabel *lblClothsetID;
    
}
//@property (nonatomic, strong) Workorder *workorder;
//@property (nonatomic, strong) id<WorkordersSplitViewDelegate> workorderSplitViewController;
@property (strong, nonatomic) IBOutlet UIView *viewSketchTools;
@property (nonatomic, assign) BOOL toolbarIsHidden;
//@property (nonatomic, strong) WorkOrderInfoPanelController *workorderInfoPanel;
//@property (nonatomic, strong) UIPopoverController *workorderInfoPanelPopover;
//@property (nonatomic, strong) SketchOptionsPanelController *sketchOptionsPanel;
//@property (nonatomic, strong) UIPopoverController *sketchOptionsPanelPopover;
//@property (nonatomic, assign) NSInteger currentSetSelectorIndex;


// IBActions
- (IBAction)btnTemplates:(id)sender;
//- (IBAction)showSketchOptionsPanelTapped:(id)sender;
//- (IBAction)showWorkorderInfoPanelTapped:(id)sender;
//- (IBAction)showFabricPanelTapped:(id)sender;
//- (IBAction)measurementsTapped:(id)sender;
//- (IBAction)setSelectorChanged:(id)sender;
//- (IBAction)newClothsetTapped:(id)sender;
//- (void)newClothsetLongPressed:(id)sender;
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

- (void)copySketchTapped:(id)sender;
- (void)pasteSketchTapped:(id)sender;
- (void)sketchOptionsCameraTapped:(id)sender;


//Custom Status getters
- (SketchView*) currentSketchView;
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
