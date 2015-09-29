# QRReaderLib
QRReader is a library for reading data from QR Code. It is layered on the top of AVMetadataObject and it provides an interface for reading metadata. 

QRReader used AVCaptureMetadataOutput for face detection.

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
* Note : Need to add bridging header for swift implementation.
```swift
QRReader.dataFromView(view, completionHandler: { (readableCodeObject) -> Void in
   // Metadata
   print("QR Code: < \(readableCodeObject.stringValue) >")
}) { (error) -> Void in
    // Error callback
   print("Error: <\(error.domain) : \(error.localizedDescription)>")
}
```
### To retrieve image from screen buffer in swift ###
```
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
