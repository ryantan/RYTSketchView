//
//  UIView+LayoutHelper.m
//  leendy
//
//  Created by Ryan Tan on 9/3/13.
//  Copyright (c) 2013 Ryan Tan. All rights reserved.
//

#import "UIView+LayoutHelper.h"

@implementation UIView (LayoutHelper)

@dynamic left,right,top,bottom;

- (CGFloat)left{
    return self.frame.origin.x;
}

- (CGFloat)right{
    return self.frame.origin.x + self.bounds.size.width;
}

- (CGFloat)top{
    return self.frame.origin.y;
}

-(CGFloat)bottom{
    return self.frame.origin.y + self.bounds.size.height;
}


@end
