//
//  PenColorViewController.m
//  RYTSketchView
//
//  Created by Ryan Tan on 3/6/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import "RYTSketchPenOptionsViewController.h"
//#import <RYTSketchView/RYTSketchView.h>
#import "RYTSketchView.h"

@interface RYTSketchPenOptionsViewController () {
    UIButton *btnThick1;
    UIButton *btnThick2;
    UIButton *btnThick3;
    
    UIButton *btnColor1;
    UIButton *btnColor2;
    UIButton *btnColor3;
    UIButton *btnColor4;
    UIButton *btnColor5;
    UIButton *btnColor6;
    
    UIButton *btnMarqueeTool;
}

@end

@implementation RYTSketchPenOptionsViewController

@synthesize sketchView, popoverController;

- (void)loadView {
    
    UIView *theView = [[UIView alloc] init];
    
    //UIView *wrapper = [[UIView alloc]initWithFrame:CGRectMake(10, 20, 170, 170)];
    UIView *wrapper = [[UIView alloc]initWithFrame:CGRectMake(10, 20, 170, 230)];
    
    btnThick1 = [UIButton buttonWithType:UIButtonTypeCustom];
    btnThick1.frame = CGRectMake(0, 0, 42, 42);
    btnThick1.tag = 1;
    [btnThick1 setBackgroundImage:[UIImage imageNamed:@"penThick1"] forState:UIControlStateNormal];
    [btnThick1 setBackgroundImage:[UIImage imageNamed:@"penThick1-selected"] forState:(UIControlStateSelected)];
    [btnThick1 addTarget:self action:@selector(thicknessTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    btnThick2 = [UIButton buttonWithType:UIButtonTypeCustom];
    btnThick2.frame = CGRectMake(60, 0, 42, 42);
    btnThick2.tag = 2;
    [btnThick2 setBackgroundImage:[UIImage imageNamed:@"penThick2"] forState:UIControlStateNormal];
    [btnThick2 setBackgroundImage:[UIImage imageNamed:@"penThick2-selected"] forState:(UIControlStateSelected)];
    [btnThick2 addTarget:self action:@selector(thicknessTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    btnThick3 = [UIButton buttonWithType:UIButtonTypeCustom];
    btnThick3.frame = CGRectMake(120, 0, 42, 42);
    btnThick3.tag = 3;
    [btnThick3 setBackgroundImage:[UIImage imageNamed:@"penThick3"] forState:UIControlStateNormal];
    [btnThick3 setBackgroundImage:[UIImage imageNamed:@"penThick3-selected"] forState:(UIControlStateSelected)];
    [btnThick3 addTarget:self action:@selector(thicknessTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    btnColor1 = [self makeColorButtonWithTag:1 imageName:@"penBlack"];
    btnColor2 = [self makeColorButtonWithTag:2 imageName:@"penSky"];
    btnColor3 = [self makeColorButtonWithTag:3 imageName:@"penSteel"];
    btnColor4 = [self makeColorButtonWithTag:4 imageName:@"penGreen"];
    btnColor5 = [self makeColorButtonWithTag:5 imageName:@"penRuby"];
    btnColor6 = [self makeColorButtonWithTag:6 imageName:@"penBurgundy"];
    btnColor1.frame = CGRectMake(0, 60, 42, 42);
    btnColor2.frame = CGRectMake(60, 60, 42, 42);
    btnColor3.frame = CGRectMake(120, 60, 42, 42);
    btnColor4.frame = CGRectMake(0, 120, 42, 42);
    btnColor5.frame = CGRectMake(60, 120, 42, 42);
    btnColor6.frame = CGRectMake(120, 120, 42, 42);
    
    btnMarqueeTool = [UIButton buttonWithType:UIButtonTypeCustom];
    btnMarqueeTool.frame = CGRectMake(0, 180, 170, 42);
    btnMarqueeTool.tag = 31;
    [btnMarqueeTool setBackgroundImage:[[UIImage imageNamed:@"ButtonWhiteStretchy"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:16.0] forState:UIControlStateNormal];
    [btnMarqueeTool setTitle:@"Marquee" forState:UIControlStateNormal];
    [btnMarqueeTool setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[btnMarqueeTool titleLabel] setFont:[UIFont systemFontOfSize:12.0]];
    [btnMarqueeTool addTarget:self action:@selector(marqueeToolTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [wrapper addSubview:btnThick1];
    [wrapper addSubview:btnThick2];
    [wrapper addSubview:btnThick3];
    [wrapper addSubview:btnColor1];
    [wrapper addSubview:btnColor2];
    [wrapper addSubview:btnColor3];
    [wrapper addSubview:btnColor4];
    [wrapper addSubview:btnColor5];
    [wrapper addSubview:btnColor6];
    [wrapper addSubview:btnMarqueeTool];
    
    [theView addSubview:wrapper];
    //theView.backgroundColor = [UIColor colorWithRGBHex:0xfffefa];
    theView.backgroundColor = [UIColor colorWithRed:255.0 green:254.0 blue:250.0 alpha:1.0];
    
    self.view = theView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.preferredContentSize = CGSizeMake(190, 190);
    self.preferredContentSize = CGSizeMake(190, 250);
    
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.sketchView){
        btnThick1.selected = FALSE;
        btnThick2.selected = FALSE;
        btnThick3.selected = FALSE;
        
        switch ([self.sketchView getPenThickness]) {
            case 1: btnThick1.selected = TRUE; break;
            case 2: btnThick2.selected = TRUE; break;
            case 3: btnThick3.selected = TRUE; break;
            default: btnThick1.selected = TRUE; break;
        }
        
        btnColor1.selected = FALSE;
        btnColor2.selected = FALSE;
        btnColor3.selected = FALSE;
        btnColor4.selected = FALSE;
        btnColor5.selected = FALSE;
        btnColor6.selected = FALSE;
        
        switch (self.sketchView.penColorIndex) {
            case 1: btnColor1.selected = TRUE; break;
            case 2: btnColor2.selected = TRUE; break;
            case 3: btnColor3.selected = TRUE; break;
            case 4: btnColor4.selected = TRUE; break;
            case 5: btnColor5.selected = TRUE; break;
            case 6: btnColor6.selected = TRUE; break;
            default: btnColor1.selected = TRUE; break;
        }
        
    }else{
        NSLog(@"PenOptionsViewController, sketchView is not set!");
    }
    //set selections based on sketchView property
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}



- (void)thicknessTapped:(id)sender {

    btnThick1.selected = FALSE;
    btnThick2.selected = FALSE;
    btnThick3.selected = FALSE;
    
    UIButton *btn = (UIButton*)sender;
    btn.selected = TRUE;
    NSInteger thickness = btn.tag;
    
    if (self.sketchView){
        [self.sketchView setPenThickness:thickness];
    }else{
        NSLog(@"Error: PenOptionsViewController, sketchView is not set!");
    }
    
    [self dismissPopover];
}

- (void)colorTapped:(id)sender{
    
    btnColor1.selected = NO;
    btnColor2.selected = NO;
    btnColor3.selected = NO;
    btnColor4.selected = NO;
    btnColor5.selected = NO;
    btnColor6.selected = NO;
    
    UIButton *btn = (UIButton*)sender;
    btn.selected = TRUE;
    NSInteger colorID = btn.tag;
    
    if (self.sketchView){
        self.sketchView.penColorIndex = colorID;
    }else{
        NSLog(@"Error: PenOptionsViewController, sketchView is not set!");
    }
    
    [self dismissPopover];
}

- (void)marqueeToolTapped:(id)sender{
    NSLog(@"marqueeToolTapped in PenOptionsViewController!");
    [self.sketchView marqueeToolSelected];
    [self dismissPopover];
}

- (UIButton*)makeColorButtonWithTag:(NSInteger)tag imageName:(NSString*)imageName{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = tag;
    
    [btn setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:[imageName stringByAppendingString:@"-selected"]] forState:(UIControlStateSelected)];
    [btn addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)dismissPopover {
    
    if (self.popoverController){
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

@end
