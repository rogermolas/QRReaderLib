//
//  QRReader.m
//  QRReader
//
//  Created by Roger Molas on 9/17/15.
//  Copyright © 2015 Roger Molas. All rights reserved.
//

#import "QRReader.h"

typedef  void(^QRCompletionWithImage)(QRReaderReadableCodeObject *code, UIImage *image);
typedef  void(^QRCompletionHandler)(QRReaderReadableCodeObject *code);
typedef  void(^QRErrorHandler)(NSError *error);

static QRCompletionWithImage QRCodeWithImage;
static QRCompletionHandler QRCode;
static QRErrorHandler QRError;

static BOOL is_reading_data                 = NO;
static char * const queue_label             = "QRReader.queue.read.data";
static char * const error_domain            = "QRReaderErrorDomain";
static int16_t const error_domain_code      = 102;

static dispatch_queue_t dispatchQueue() {
    dispatch_queue_t _dispatchQueue = nil;
    _dispatchQueue = dispatch_queue_create(queue_label, NULL);
    return _dispatchQueue;
}

static QRReader * initialize_once() {
    static QRReader *reader = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{reader = [[QRReader alloc] init];});
    return reader;
}

static void reset_all_call_backs() {
    QRCodeWithImage = nil;
    QRCode = nil;
    QRError = nil;
}

@protocol QRReaderExtended <
AVCaptureMetadataOutputObjectsDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@interface QRReader() <QRReaderExtended> {
    @private
        QRReaderReadableCodeObject *QRReadableCode;
        NSString * metadataObjectType;
        UIView *viewPreview;
    
        AVCaptureSession *captureSession;
        AVCaptureStillImageOutput *stillImageOutput;
        AVCaptureVideoPreviewLayer *videoPreviewLayer;
}
@end


@implementation QRReader

#pragma mark -
#pragma mark - Public Methods

+ (void)dataFromView:(UIView *)preview
   completionHandler:(QRCompletionHandler)completionBlock
        errorHandler:(QRErrorHandler)errorBlock {
    
    reset_all_call_backs();
    
    QRReader *reader = initialize_once();
    reader->captureSession = nil;
    reader->viewPreview = preview;
    reader->metadataObjectType = AVMetadataObjectTypeQRCode;
    
    QRCode = [completionBlock copy];
    QRError = [errorBlock copy];
    [reader QR_StartReadingData];
}

+ (void)dataFromView:(UIView *)preview
                type:(NSString *)type
   completionHandler:(QRCompletionWithImage)completionBlock
        errorHandler:(QRErrorHandler)errorBlock {
    
    reset_all_call_backs();
    
    QRReader *reader = initialize_once();
    reader->captureSession = nil;
    reader->viewPreview = preview;
    reader->metadataObjectType = type;
    
    QRCodeWithImage = [completionBlock copy];
    QRError = [errorBlock copy];
    [reader QR_StartReadingData];
}

#pragma mark -
#pragma mark Private Methods

- (void)QR_StartReadingData {
    
    is_reading_data = YES;
    NSError *error = nil;
    NSArray *deviceArray = [AVCaptureDevice devices];
    AVCaptureDeviceInput *input;
    
    for (AVCaptureDevice *device in deviceArray) {
        if (device.position == AVCaptureDevicePositionFront) {
            NSLog(@"Front Cam: %@", device);
            input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        }
    }
    
    if (!input) {
        error = [NSError errorWithDomain:[NSString stringWithUTF8String:error_domain]
                                    code:error_domain_code
                                userInfo:@{@"class":NSStringFromClass(self.class)}];
        QRError(error);
    }
    
    self->captureSession = [[AVCaptureSession alloc] init];
    [self->captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self->captureSession addOutput:captureMetadataOutput];
    
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue()];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:self->metadataObjectType]];
    
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
                QRCodeWithImage(QRReadableCode,image);
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
        if (metadataObject.type == self->metadataObjectType) {
            dispatch_async(dispatch_get_main_queue(), ^{
                QRReadableCode = metadataObject;
                if (QRCode)
                    QRCode(QRReadableCode);
                
                [weakSelf QR_CaptureImage];
            });
        };
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        is_reading_data = NO;
        [weakSelf->captureSession stopRunning];
        weakSelf->captureSession = nil;
    });
}

@end
