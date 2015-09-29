//
//  ViewController.m
//  Demo
//
//  Created by Roger Molas on 9/17/15.
//  Copyright © 2015 KLab Cyscorpions. All rights reserved.
//

#import "ViewController.h"
#import "QRReader.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [QRReader dataFromView:self.view completionHandler:^(QRReaderReadableCodeObject *code) {
        
        NSLog(@"QR Code:< %@ >",code.stringValue);
        
    } errorHandler:^(NSError *error) {
        
        NSLog(@"Error: <%@ : %@>", error.domain, error.localizedDescription);
    }];
}

@end
