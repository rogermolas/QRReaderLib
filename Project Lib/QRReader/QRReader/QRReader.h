//
//  QRReader.h
//  QRReader
//
//  Created by Roger Molas on 9/17/15.
//  Copyright © 2015 Roger Molas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef AVMetadataMachineReadableCodeObject QRReaderReadableCodeObject;

@interface QRReader : NSObject

+ (void)dataFromView:(UIView *)preview
   completionHandler:(void(^)(QRReaderReadableCodeObject *code))completionBlock
        errorHandler:(void(^)(NSError *error))errorBlock;

+ (void)dataFromView:(UIView *)preview
                type:(NSString *)type
   completionHandler:(void(^)(QRReaderReadableCodeObject *code, UIImage *image))completionBlock
        errorHandler:(void(^)(NSError *error))errorBlock;

@end
