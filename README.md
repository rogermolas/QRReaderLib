# QRReaderLib
QRReader is a library for reading data from QR Code. It is layered on the top of AVMetadataObject and it provides an interface for reading metadata. 

QRReader used AVCaptureMetadataOutput for face detection.

# Installation
1. $ git clone https://github.com/KLabCyscorpions/QRReaderLib.git
2. Drag the "build/QRReader" directory to your project source code.
3. Build and run your project, if build succeeded you can proceed to implementation.
4. If there's an error try to modify your library search path in project build settings.

* Note QRReader Static Library (.a file) is not supported in Swift you can use the files in "/Project Lib/QRReader/QRReader, and add bridging header for swift.
    
# Objective C 
### Implementation ###
``` objc
[QRReader dataFromView:self.view completionHandler:^(QRReaderReadableCodeObject *code) {
   // Metadata code
   NSLog(@"QR Code:< %@ >",code.stringValue);
} errorHandler:^(NSError *error) {
   NSLog(@"Error: <%@ : %@>", error.domain, error.localizedDescription);
}];
```
    
### To retrieve image from screen buffer ###
```objc
[QRReader dataWithImageFromView:self.view completionHandler:^(QRReaderReadableCodeObject *code, UIImage *image) {
   // Metadata code
   NSLog(@"QR Code:< %@ >",code.stringValue);
   // Save image to photo album
   UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
} errorHandler:^(NSError *error) {
   // Error callback
   NSLog(@"Error: <%@ : %@>", error.domain, error.localizedDescription);
}];
```
# Swift
```swift
QRReader.dataFromView(view, completionHandler: { (readableCodeObject) -> Void in
   // Metadata
   print("QR Code: < \(readableCodeObject.stringValue) >")
}) { (error) -> Void in
    // Error callback
   print("Error: <\(error.domain) : \(error.localizedDescription)>")
}
```
### To retrieve image from screen buffer ###
```swift
QRReader.dataWithImageFromView(view, completionHandler: { (readableCodeObject, image) -> Void in
   // Metadata
   print("QR Code: < \(readableCodeObject.stringValue) >")
   // Save image to photo album
   UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}) { (error) -> Void in
   // Error callback
   print("Error: <\(error.domain) : \(error.localizedDescription)>")
}
```
