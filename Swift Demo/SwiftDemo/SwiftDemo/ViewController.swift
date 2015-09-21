//
//  ViewController.swift
//  SwiftDemo
//
//  Created by Keith Samson on 21/09/2015.
//  Copyright © 2015 KLab Cyscorpions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        
        super.viewDidLoad()

        QRReader.dataFromView(view, completionHandler: { (readableCodeObject) -> Void in
            
            print("QR Code: < \(readableCodeObject.stringValue) >")
            
            }) { (error) -> Void in
                
                print("Error: <\(error.domain) : \(error.localizedDescription)>")
        }
    }
}

