//
//  QRReader.h
//  QRReader
//
//  Created by Roger Molas on 9/17/15.
//  Copyright © 2015 KLab Cyscorpions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/*! @typedef QRReaderReadableCodeObject
    @abstract QR object readable code respresentation
 */
typedef AVMetadataMachineReadableCodeObject QRReaderReadableCodeObject NS_AVAILABLE(NA, 7_0);

/*! @typedef QRCaptureDevicePosition
    @abstract
        Indicate the physical position of an AVCaptureDevice's hardware on the system.
 
    @constant QRCaptureDevicePositionBack
        Indicates that the device is physically located on the back of the system hardware.
    @constant QRCaptureDevicePositionFront
        Indicates that the device is physically located on the front of the system hardware.
 */
typedef NS_ENUM(NSInteger, QRCaptureDevicePosition) {
    QRCaptureDevicePositionBack  = 1,
    QRCaptureDevicePositionFront = 2
} NS_AVAILABLE(10_7, 4_0);

/*!
 @class QRReader
 
 @abstract
    QRReader is an abstract based class that defines an interface for reading QR code it use a metadata object use by AVFoundation.
 
 @discussion
    QRReader is layered on the top of AVMetadataObject class it provides an interface for reading QR code metadata
   
    It use the "AVMetadataObjectTypeQRCode" metadata object type from AVMetadataObject
 
    The concrete AVCaptureMetadataOutput is used by QRReader for face detection.
 */
NS_CLASS_AVAILABLE(10_7, 4_0)
@interface QRReader : NSObject

/// -------------------------------------------------------
/// @name Perform operation
/// -------------------------------------------------------
/*!
 @method
    dataFromView: completionHandler: errorHandler:
    
 @abstract
    Performing the reading operation based on the source provided(camera source view)
 
 @param preview
    Specify the source view(UIView) object.
 @param completionBlock
    Completion callback it return 'QRReaderReadableCodeObject' metadata (e.g QR Code in NSData representation)
 @param errorBlock
    Error callback (e.g When source view is nil)
 */
+ (void)dataFromView:(UIView *)preview completionHandler:(void(^)(QRReaderReadableCodeObject *code))completionBlock errorHandler:(void(^)(NSError *error))errorBlock;

/*!
 @method
    dataWithImageFromView: type: completionHandler: errorHandler:
 
 @abstract
    Performing the reading operation based on the source provided(camera source view)
 
 @param preview
    Specify the source view(UIView) object.
 @param completionBlock
    Completion callback it return 'QRReaderReadableCodeObject' metadata (e.g QR Code in NSData representation)
    and UIImage object from source buffer
 @param errorBlock
    Error callback (e.g When source view is nil)
 */
+ (void)dataWithImageFromView:(UIView *)preview completionHandler:(void(^)(QRReaderReadableCodeObject *code, UIImage *image))completionBlock errorHandler:(void(^)(NSError *error))errorBlock;

/// -------------------------------------------------------
/// @name Settings
/// -------------------------------------------------------
/*!
 @method
    setDeviceCapturePosition:
 
 @abstract
    Set the device camera position
    
 @param position
    Specify the device camera position
 */
+ (void)setDeviceCapturePosition:(QRCaptureDevicePosition)position;

@end
