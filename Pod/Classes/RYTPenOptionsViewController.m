//
//  PenColorViewController.m
//  RYTSketchView
//
//  Created by Ryan Tan on 3/6/12.
//  Copyright (c) 2012 Ryan Tan. All rights reserved.
//

#import "RYTPenOptionsViewController.h"
#import "SketchViewController.h"
#import "RYTSketchView.h"
#import "UIColor-Expanded.h"

@interface RYTPenOptionsViewController ()

@end

@implementation RYTPenOptionsViewController

@synthesize sketchView, sketchViewController;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    [self.view addSubview:wrapper];
    
    self.view.backgroundColor = [UIColor colorWithRGBHex:0xfffefa];
    
    //self.view.frame = CGRectMake(0, 0, 190, 190);
    self.view.frame = CGRectMake(0, 0, 190, 250);
    //self.contentSizeForViewInPopover = CGSizeMake(190, 190);
    self.contentSizeForViewInPopover = CGSizeMake(190, 250);
    
}

- (void)viewDidAppear:(BOOL)animated{
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
                //default: btnColor1.selected = TRUE; break;
        }
        
    }else{
        NSLog(@"PenOptionsViewController, sketchView is not set!");
    }
    //set selections based on sketchView property
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



- (void)thicknessTapped:(id)sender{

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
    
    [self.sketchViewController performSelector:@selector(dismissAllPopovers) withObject:Nil afterDelay:0.2];
    //[self.sketchViewController dismissAllPopovers];
}

- (void)colorTapped:(id)sender{
    
    btnColor1.selected = FALSE;
    btnColor2.selected = FALSE;
    btnColor3.selected = FALSE;
    btnColor4.selected = FALSE;
    btnColor5.selected = FALSE;
    btnColor6.selected = FALSE;
    
    
    UIButton *btn = (UIButton*)sender;
    btn.selected = TRUE;
    NSInteger colorID = btn.tag;
    
    if (self.sketchView){
        [self.sketchView setPenColorIndex:colorID];
    }else{
        NSLog(@"Error: PenOptionsViewController, sketchView is not set!");
    }
    
    [self.sketchViewController performSelector:@selector(dismissAllPopovers) withObject:Nil afterDelay:0.2];
    //[self.sketchViewController dismissAllPopovers];
}

- (void)marqueeToolTapped:(id)sender{
    NSLog(@"marqueeToolTapped in PenOptionsViewController!");
    [self.sketchView marqueeToolSelected];
    [self.sketchViewController dismissAllPopovers];
}

- (UIButton*)makeColorButtonWithTag:(NSInteger)tag imageName:(NSString*)imageName{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = tag;
    
    [btn setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:[imageName stringByAppendingString:@"-selected"]] forState:(UIControlStateSelected)];
    [btn addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

@end
