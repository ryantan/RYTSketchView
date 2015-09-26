//
//  RYTSketchViewUtils.h
//  Pods
//
//  Created by Ryan on 20/6/15.
//
//

#import <Foundation/Foundation.h>

@interface RYTSketchViewUtils : NSObject


CGContextRef CreateBitmapContext(NSUInteger w, NSUInteger h);
+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize;
+ (UIImage *)getUIImageFromCGContext:(CGContextRef)context;

+ (void)writeImage:(UIImage*)image toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument;

+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name;
+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name withPath:(NSString*)path;
+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument;

+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name;
+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name withPath:(NSString*)path;
+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument;

@end
