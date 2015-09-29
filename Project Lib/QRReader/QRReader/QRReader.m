//
//  QRReader.m
//  QRReader
//
//  Created by Roger Molas on 9/17/15.
//  Copyright © 2015 KLab Cyscorpions. All rights reserved.
//

#import "QRReader.h"

typedef  void(^QRCompletionWithImage)(QRReaderReadableCodeObject *code, UIImage *image);
typedef  void(^QRCompletionHandler)(QRReaderReadableCodeObject *code);
typedef  void(^QRErrorHandler)(NSError *error);
// Callback
static QRCompletionWithImage    QRCodeWithImage;
static QRCompletionHandler      QRCode;
static QRErrorHandler           QRError;
// Defaults
static char *   const queue_label           = "QRReader.queue.read.data";
static char *   const error_source_domain   = "QRReaderErrorDomain : Source Not Found";
static char *   const error_reading_domain  = "QRReaderErrorDomain : Failed Reading Data";
static int32_t  const error_domain_code     = 0x00000066;
static int32_t  d_position                  = 0x00000002; // (Front) Default position
static BOOL     is_reading_data             = NO;         // Initialize to false(NO)

static dispatch_queue_t dispatchQueue() {
    dispatch_queue_t _dispatchQueue = nil;
    _dispatchQueue = dispatch_queue_create(queue_label, NULL);
    return _dispatchQueue;
}
// Single instance
static QRReader * initialize_once() {
    static QRReader *reader = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{ reader = [[QRReader alloc] init]; });
    return reader;
}

static void reset_all_callback() {
    QRCodeWithImage = nil;
    QRCode = nil;
    QRError = nil;
}
// Protocol
@protocol QRReaderExtended <
AVCaptureMetadataOutputObjectsDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@interface QRReader() <QRReaderExtended> {
@private  // Private instance
    UIView *viewPreview;
    AVCaptureSession *captureSession;
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    QRReaderReadableCodeObject *QRReadableCode;
}
@end

@implementation QRReader

#pragma mark -
#pragma mark - Public Methods

+ (void)dataFromView:(UIView *)preview
   completionHandler:(QRCompletionHandler)completionBlock
        errorHandler:(QRErrorHandler)errorBlock {
    
    reset_all_callback();
    
    QRReader *reader = initialize_once();
    reader->captureSession = nil;
    reader->viewPreview = preview;
    
    QRCode = [completionBlock copy];
    QRError = [errorBlock copy];
    [reader QR_StartReadingData];
}

+ (void)dataWithImageFromView:(UIView *)preview
            completionHandler:(void(^)(QRReaderReadableCodeObject *code, UIImage *image))completionBlock
                 errorHandler:(void(^)(NSError *error))errorBlock {
    
    reset_all_callback();
    
    QRReader *reader = initialize_once();
    reader->captureSession = nil;
    reader->viewPreview = preview;
    
    QRCodeWithImage = [completionBlock copy];
    QRError = [errorBlock copy];
    [reader QR_StartReadingData];
}

+ (void)setDeviceCapturePosition:(QRCaptureDevicePosition)position {
    d_position = position;
}

#pragma mark -
#pragma mark Private Methods

- (void)QR_StartReadingData {
    
    is_reading_data = YES;
    NSError *error = nil;
    NSArray *deviceArray = [AVCaptureDevice devices];
    AVCaptureDeviceInput *input;
    // identify input source
    for (AVCaptureDevice *device in deviceArray) {
        if (device.position == d_position) {
            input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        }
    }
    
    if (!input) {
        error = [NSError errorWithDomain:[NSString stringWithUTF8String:error_source_domain]
                                    code:error_domain_code
                                userInfo:@{@"info":@"Input not found"}];
        QRError(error);
    }
    
    self->captureSession = [[AVCaptureSession alloc] init];
    [self->captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self->captureSession addOutput:captureMetadataOutput];
    
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue()]; //spawn in main thread
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]]; //Metadata type
    
    self->stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self->stillImageOutput setOutputSettings:outputSettings];
    
    [self->captureSession addOutput:self->stillImageOutput];
    
    self->videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self->captureSession];
    [self->videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self->videoPreviewLayer setFrame:self->viewPreview.frame];
    
    [self->videoPreviewLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [self->viewPreview.layer addSublayer:self->videoPreviewLayer];
    [self->captureSession startRunning];
}

- (void)QR_CaptureImage {
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self->stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    //Capture Completion Handler
    typedef void(^CompletionHandler)(CMSampleBufferRef imageSampleBuffer, NSError *error);
    CompletionHandler action  = ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        if(imageSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            if (QRCodeWithImage)
                QRCodeWithImage(QRReadableCode,image); // return metada & image
        }
    };
    [self->stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                        completionHandler:action];
}

#pragma mark -
#pragma mark AVFoundation / AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    __block typeof (self) weakSelf = self;
    if (metadataObjects!= nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        if (metadataObject.type == AVMetadataObjectTypeQRCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                QRReadableCode = metadataObject;
                
                if (QRCode) {
                    QRCode(QRReadableCode); // return metadata only
                }
                
                if (QRCodeWithImage) {
                    [weakSelf QR_CaptureImage]; // Cature sreen buffer
                }
                
                is_reading_data = NO;
                [weakSelf->captureSession stopRunning];
                weakSelf->captureSession = nil;
            });
        };
    
    } else {
        QRError([NSError errorWithDomain:[NSString stringWithUTF8String:error_reading_domain]
                                        code:error_domain_code
                                    userInfo:@{@"info":@"Failed reading data"}]);
    }
}
@end
