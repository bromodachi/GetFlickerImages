//
//  textFieldDelegate.swift
//  FIndPicture
//
//  Created by Conrado Uraga on 2015/10/10.
//  Copyright © 2015年 Conrado Uraga. All rights reserved.
//

import UIKit

class textFieldDelgate : NSObject, UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("testing something")
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("printing something agian")
        return true
    }
    
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}