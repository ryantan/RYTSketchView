//
//  RYTSketchViewUtils.m
//  Pods
//
//  Created by Ryan on 20/6/15.
//
//

#import "RYTSketchViewUtils.h"

#import <QuartzCore/QuartzCore.h>

@implementation RYTSketchViewUtils



//void * globalBitmapData = NULL;



CGContextRef CreateBitmapContext(NSUInteger w, NSUInteger h){
    CGContextRef    context = NULL;
    
    /*
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow   = (w * 4);
    //bitmapBytesPerRow   = (w * 8);
    
    bitmapByteCount     = (bitmapBytesPerRow * h);
    
    if(globalBitmapData == NULL){
        globalBitmapData = malloc( bitmapByteCount );
    }
    memset(globalBitmapData, 0, sizeof(globalBitmapData));
    if (globalBitmapData == NULL){
        return nil;
    }*/
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    
    //context = CGBitmapContextCreate (globalBitmapData,w,h,8,bitmapBytesPerRow,colorspace,kCGImageAlphaPremultipliedLast);
    //context = CGBitmapContextCreate (NULL,w,h,8,bitmapBytesPerRow,colorspace,kCGImageAlphaPremultipliedLast);
    //context = CGBitmapContextCreate(NULL, w, h, 8, bitmapBytesPerRow, colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    //context = CGBitmapContextCreate(globalBitmapData, w, h, 8, bitmapBytesPerRow, colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    context = CGBitmapContextCreate(NULL, w, h, 8, 0, colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorspace);
    
    return context;
}
+ (NSString *)getDocumentPath{
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [pathList  objectAtIndex:0];
    return path;
}

+ (void)writeSketchForContent:(UIImage *)sketch{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path = [RYTSketchViewUtils getFilePathForSketch];
    
    NSLog(@"RYTSketchViewUtils::writeSketchForContent, path=%@",path);
    
    [UIImagePNGRepresentation(sketch) writeToFile:path atomically:YES];
    
    // Check to see if files were successfully written
    if(![fileMgr fileExistsAtPath:path]) {
        NSLog(@"Sketch not saved, path=%@", path);
    }else{
        NSLog(@"sketch saved, path=%@", path);
    }
    
}

+ (NSString *)getFilePathForSketch {
    NSString *path = [RYTSketchViewUtils getDirectoryPathForSketch];
    NSString *fileName = [RYTSketchViewUtils getFileNameForSketch];
    path = [path stringByAppendingPathComponent:fileName];
    return path;
}

+ (NSString *)getDirectoryPathForSketch {
    NSString *directoryName = @"RYTSketchView";
    NSString *path = [RYTSketchViewUtils getDocumentPath];
    path = [path stringByAppendingPathComponent:directoryName];
    
    //Create if not exists
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    
    BOOL isDir;
    if (![manager fileExistsAtPath:path isDirectory:&isDir]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        NSLog(@"Creating folder");
        
        
        //Make sure it exists
        if (![manager fileExistsAtPath:path isDirectory:&isDir]) {
            NSLog(@"Workorder folder cannot be created.");
        }else{
            if (isDir){
                NSLog(@"Workorder folder is created.");
            }else{
                NSLog(@"Workorder folder is created but it is not a directory?");
            }
        }
    }
    
    
    return path;
}

+ (NSString *)getFileNameForSketch {
    NSUInteger sketchID = 1;
    NSString *fileName = [[NSString alloc]initWithFormat:@"sketch_%lu.png", (unsigned long)sketchID];
    return fileName;
}

+ (NSString *)getThumbnailNameForSketch {
    NSUInteger sketchID = 1;
    NSString *fileName = [[NSString alloc]initWithFormat:@"sketch_%lu_thumb.png", (unsigned long)sketchID];
    return fileName;
}


+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)getUIImageFromCGContext:(CGContextRef)context {
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* img = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    //CGContextRelease(context);
    return img;
}

+ (void)writeImage:(UIImage*)image toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument{
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if (isRelativeToDocument){
        NSString *docPath = [RYTSketchViewUtils getDocumentPath];
        path = [docPath stringByAppendingPathComponent:path];
    }
    
    //NSLog(@"RYTSketchViewUtils->writeImage:toPath:isRelativeToDocument:, path=%@",path);
    
    
    BOOL isDir;
    if (![fileMgr fileExistsAtPath:path isDirectory:&isDir]) {
        [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        NSLog(@"Creating folder");
    }
    
    path = [path stringByAppendingPathComponent:name];
    
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    
    
    // Check to see if files were successfully written
    if(![fileMgr fileExistsAtPath:path]) {
        //NSLog(@"Image not saved, path=%@", path);
    }else{
        //NSLog(@"Image saved, path=%@", path);
    }
    
}

+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name {
    [RYTSketchViewUtils writeCGImage:image toFileName:name withPath:@"debug"];
}

+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name withPath:(NSString*)path {
    [RYTSketchViewUtils writeCGImage:image toFileName:name withPath:path isRelativeToDocument:YES];
}

+ (void)writeCGImage:(CGImageRef)image toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument {
    UIImage *imageToBeWritten = [UIImage imageWithCGImage:image];
    [RYTSketchViewUtils writeImage:imageToBeWritten toFileName:name withPath:path isRelativeToDocument:isRelativeToDocument];
}

+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name {
    [RYTSketchViewUtils writeCGContext:context toFileName:name withPath:@"debug"];
}

+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name withPath:(NSString*)path {
    [RYTSketchViewUtils writeCGContext:context toFileName:name withPath:path isRelativeToDocument:YES];
}

+ (void)writeCGContext:(CGContextRef)context toFileName:(NSString*)name withPath:(NSString*)path isRelativeToDocument:(BOOL)isRelativeToDocument {
    UIImage *imageToBeWritten = [RYTSketchViewUtils getUIImageFromCGContext:context];
    [RYTSketchViewUtils writeImage:imageToBeWritten toFileName:name withPath:path isRelativeToDocument:isRelativeToDocument];
}



@end