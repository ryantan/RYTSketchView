//
//  ClothsetOptionsPopoverController.m
//  RYTSketchView
//
//  Created by Ryan Tan on 15/8/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import "RYTSketchOptionsViewController.h"
#import <RYTSketchView/RYTSketchView.h>

@interface RYTSketchOptionsViewController () {
    UIButton *btnClear;
    UIButton *btnDelete;
    UIButton *btnCopy;
    UIButton *btnPaste;
    UIButton *btnCamera;
}

@end

@implementation RYTSketchOptionsViewController

//@synthesize sketchViewController;
@synthesize sketchView, popoverController;

- (void)loadView {
    UIView *theView = [[UIView alloc]init];
    
    UIView *wrapper = [[UIView alloc]initWithFrame:CGRectMake(10, 20, 140, 212)];
    NSInteger buttonHSpace = 42;
    
    btnClear = [UIButton buttonWithType:UIButtonTypeCustom];
    btnClear.frame = CGRectMake(0, 0, 100, 34);
    btnClear.tag = 1;
    [btnClear setBackgroundImage:[UIImage imageNamed:@"btnLabeledClear"] forState:UIControlStateNormal];
    [btnClear addTarget:self action:@selector(clearTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    /*
    btnDelete = [UIButton buttonWithType:UIButtonTypeCustom];
    btnDelete.frame = CGRectMake(0, buttonHSpace*1, 100, 34);
    btnDelete.tag = 2;
    [btnDelete setBackgroundImage:[UIImage imageNamed:@"btnLabeledDelete"] forState:UIControlStateNormal];
    [btnDelete addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
    */
    
    /*
     btnDuplicate = [UIButton buttonWithType:UIButtonTypeCustom];
     btnDuplicate.frame = CGRectMake(0, buttonHSpace*2, 100, 34);
     btnDuplicate.tag = 3;
     [btnDuplicate setBackgroundImage:[UIImage imageNamed:@"btnLabeledDup"] forState:UIControlStateNormal];
     [btnDuplicate addTarget:self action:@selector(duplicateTapped:) forControlEvents:UIControlEventTouchUpInside];
     */
    
    btnCopy = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCopy.frame = CGRectMake(0, buttonHSpace*1, 100, 34);
    btnCopy.tag = 4;
    [btnCopy setBackgroundImage:[UIImage imageNamed:@"btnLabeledCopy"] forState:UIControlStateNormal];
    [btnCopy addTarget:self action:@selector(copyTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    btnPaste = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPaste.frame = CGRectMake(0, buttonHSpace*2, 100, 34);
    btnPaste.tag = 5;
    [btnPaste setBackgroundImage:[UIImage imageNamed:@"btnLabeledPaste"] forState:UIControlStateNormal];
    [btnPaste addTarget:self action:@selector(pasteTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    btnCamera = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnCamera.frame = CGRectMake(0, buttonHSpace*3, 100, 34);
    btnCamera.tag = 6;
    [btnCamera setTitle:@"Camera" forState:UIControlStateNormal];
    //[btnCamera setBackgroundImage:[UIImage imageNamed:@"btnLabeledPaste"] forState:UIControlStateNormal];
    [btnCamera addTarget:self action:@selector(cameraTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [wrapper addSubview:btnClear];
    //[wrapper addSubview:btnDelete];
    //[wrapper addSubview:btnDuplicate];
    [wrapper addSubview:btnCopy];
    [wrapper addSubview:btnPaste];
    [wrapper addSubview:btnCamera];
    [theView addSubview:wrapper];
    
    //theView.backgroundColor = [UIColor colorWithRGBHex:0xfffefa];
    theView.backgroundColor = [UIColor colorWithRed:255.0 green:254.0 blue:205.0 alpha:1.0];
    
    self.view = theView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updatePasteButton];
    self.preferredContentSize = CGSizeMake(155, (42*4)+39);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}









#pragma mark - UIAlertView handlers

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 2){
        if (buttonIndex == 1){
            [self.sketchView clearSketch];
            [self dismissPopover];
        }
    }/*else if(alertView.tag == 3){
        if (buttonIndex == 1){
            [self.sketchView deleteSketch];
            [self dismissPopover];
        }
    }else if(alertView.tag == 4){
        if (buttonIndex == 1){
            [self.sketchView duplicateSketch];
            [self dismissPopover];
        }
    }*/
}





         
         
         
         
         
#pragma mark - Custom

- (void)updatePasteButton {
    if ([self.sketchView hasClipboardImage]){
        btnPaste.enabled = YES;
    }else{
        btnPaste.enabled = NO;
    }
}
         
- (void)clearTapped:(id)sender{
    //[self.sketchView clearSketch];
    //[self dismissPopover];
    
    [self clearSketchWithWarning:YES];
}

- (void)clearSketchWithWarning:(BOOL)withWarning {
    if (withWarning){
        NSString *message = @"Are you sure you want to clear the sketch?";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:
                              @"Clear sketch" message:message delegate:self
                                              cancelButtonTitle:@"Cancel" otherButtonTitles:@"Clear", nil];
        alert.tag = 2;
        [alert show];
    }else{
        [self.sketchView clearSketch];
        [self dismissPopover];
    }
}

/*
- (void)deleteTapped:(id)sender{
 [self.sketchView deleteSketch];
 [self dismissPopover];
}
*/

/*
- (void)duplicateTapped:(id)sender{
 [self.sketchView duplicateSketch];
 [self dismissPopover];
}
*/

- (void)copyTapped:(id)sender{
    [self.sketchView setClipboardContent];
    [self dismissPopover];
}

- (void)pasteTapped:(id)sender{
    [self.sketchView pasteClipboardWithNothingToPasteBlock:^{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Nothing to paste" message:@"Please copy before pasting" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }];
    [self dismissPopover];
}

- (void)cameraTapped:(id)sender{
    //[self.sketchView sketchOptionsCameraTapped:sender];
    
    // Dismiss existing popover controllers.
    //if (mainPopoverController != Nil){
    //    [mainPopoverController dismissPopoverAnimated:YES];
    //    mainPopoverController = Nil;
    //}
    
    // TODO: Initialize view, nav and popover controllers
    
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photosViewController];
    
    //mainPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    
    // Calculate where we are showing the popover
    //CGRect popoverRect = [self.viewSketchTools convertRect:((UIView*)sender).frame toView:self.view];
    
    // Present the popover
    //[mainPopoverController presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)dismissPopover {
    
    // TODO: Clean
    /*
    if ([self.parentViewController isKindOfClass:[UIPopoverController class]]){
        UIPopoverController *pc = (UIPopoverController *)self.parentViewController;
        [pc dismissPopoverAnimated:YES];
    }*/
    
    if (self.popoverController){
        [self.popoverController dismissPopoverAnimated:YES];
    }
    
}


@end
