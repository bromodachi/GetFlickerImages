//
//  ViewController.swift
//  FIndPicture
//
//  Created by Conrado Uraga on 2015/10/10.
//  Copyright © 2015年 Conrado Uraga. All rights reserved.
//

import UIKit

extension String {
    struct NumberFormatter {
        static let instance = NSNumberFormatter()
    }
    var floatValue:Float? {
        return NumberFormatter.instance.numberFromString(self)?.floatValue
    }
    var integerValue:Int? {
        return NumberFormatter.instance.numberFromString(self)?.integerValue
    }
}
class ViewController: UIViewController, UINavigationControllerDelegate {

    
    /* Constant variables*/
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "7cf051e9c842de383d11fa39d630f537"
    let EXTRAS = "url_m"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    let BOUNDING_BOX_WIDTH:Float = 1.0
    let BOUNDING_BOX_HEIGHT:Float = 1.0
    let LON_MIN: Float = -180.0
    let LON_MAX:Float = 180.0
    let LAT_MIN:Float = -90.0
    let LAT_MAX:Float = 90.0
    
    
    var tap: UITapGestureRecognizer!
    /*buttons and text fields*/
    @IBOutlet weak var imageSearch: UITextField!
    @IBOutlet weak var imageLabel: UILabel!
    
    @IBOutlet weak var searchedImage: UIImageView!
    @IBOutlet weak var longitude: UITextField!
    
    @IBOutlet weak var latitude: UITextField!
    
    @IBOutlet weak var searchImage: UIButton!
    
    @IBOutlet weak var searchLongLatitude: UIButton!
    
    let textDelegate = textFieldDelgate()
    
    var keyboardShowed = false
    /*end of buttons and text fields*/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageSearch.delegate = textDelegate
        self.longitude.delegate = textDelegate
        self.latitude.delegate = textDelegate
        tap = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        tap?.numberOfTapsRequired = 1
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.subscribeToKeyboardNotification()
        self.addKeyboardDismissRecognizer()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeToKeyboardNotification()
        self.removeKeyboardDismissRecognizer()
    }
    
    /*Button methods*/
    
    @IBAction func search(sender: AnyObject) {
        DismissKeyboard()
        let button = sender as! UIButton;
        if( button == searchImage){
            print("image")
            //should not be empty or just contain white spaces
            //no image, notify the users
            //else display the image on the image view
            guard let textField = imageSearch?.text else {
                imageLabel.text = "Error: Couldn't get text"
                return
            }
            guard isEmpty(textField) else{
                imageLabel.text = "Error: Empty value"
                return;
            }
            //search for the image
            /*API ARGUMENTS*/
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "text" : textField,
                "format": DATA_FORMAT,
                "extras": EXTRAS,
                "nojsoncallback": NO_JSON_CALLBACK
                
            ]
            
            /*create sesssion*/
            let session = NSURLSession.sharedSession()
            let urlString = BASE_URL + escapeParameters(methodArguments)
            
           print(urlString)
            let url = NSURL (string: urlString)!
            
            let request = NSURLRequest (URL: url)
            
            let task = session.dataTaskWithRequest(request){ (data, response, error) in
                guard (error == nil) else{
                    print("error with getting task")
                    self.imageLabel.text = "Error: server error"
                    return
                }
                guard let data = data else {
                    print ("No data!!!")
                    self.imageLabel.text = "Error: No data for search query"

                    return
                }
                
                let result: AnyObject!
                do{
                    result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                }catch{
                    result = nil
                    print("Couldn't parse data")
                     self.imageLabel.text = "Error: Couldn't parse data"
                    return
                }
               // print (result)
                guard let photosDictionary = result["photos"] as? NSDictionary else {
                    print ("no photos in query")
                    self.imageLabel.text = "Error: No photos in query"
                    return;
                }
                
                guard let totalPages = photosDictionary["pages"] as? Int else{
                    print ("Couldn't extract total pages")
                    self.imageLabel.text = "Error: Couldn't extract pages"
                    return
                }
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit)))
                self.getImageFromRandomPage(methodArguments, pageNumber: randomPage)
                
                //here
               /* guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else{
                    print ("no photos in query")
                    return;
                }
                if (totalPhotos>0){
                    guard let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print ("no photos in query")
                        return;
                    }
                    
                    let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                    let photoDictionary = photoArray[randomIndex] as [String: AnyObject]
                    print (photoArray[randomIndex])
                    let photoTitle = photoDictionary["title"] as? String
                    
                    guard let imageURLString = photoDictionary["url_m"] as? String else {
                        print("photo doesn't have an url")
                        return
                    }
                    
                    let imageURL = NSURL(string: imageURLString)
                    
                    guard let imageData = NSData(contentsOfURL: imageURL!) else {
                        print("image doesn't exist")
                        dispatch_async(dispatch_get_main_queue(), {
                            //show the image in the main thread
                            print("image doesn't exist")
                        })
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        //show the image in the main thread
                        self.searchedImage.image = UIImage(data: imageData)
                        self.imageLabel.text = photoTitle
                    })
                    
                  
                }*/
            
            }
            task.resume()
            
            
            
            
        }
        else if (button == searchLongLatitude){
            print("long")
            //should not be empty or just contain white spaces
            //latitude must be numbers between -90 and 90
            //longitude must be between -180 and 180
            //no image, notify the users
            //else display the image on the image view
            
            guard checkLongAndLatContainNoErrors() else {
                print ("Error, can not be empty")
                self.imageLabel.text = "Error: Empty strings in longitude and/or latitude boxes"
                return
            }
            //commence search
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox" : getBbox(longitude.text!, lat: latitude.text!),
                "format": DATA_FORMAT,
                "extras": EXTRAS,
                "nojsoncallback": NO_JSON_CALLBACK
                
            ]
            
            /*create sesssion*/
            let session = NSURLSession.sharedSession()
            let urlString = BASE_URL + escapeParameters(methodArguments)
            
            print(urlString)
            let url = NSURL (string: urlString)!
            
            let request = NSURLRequest (URL: url)
            
            let task = session.dataTaskWithRequest(request){ (data, response, error) in
                guard (error == nil) else{
                    print("error with getting task")
                    self.imageLabel.text = "Error: Server Error"
                    return
                }
                guard let data = data else {
                    print ("No data!!!")
                    self.imageLabel.text = "Error: No data"
                    return
                }
                
                let result: AnyObject!
                do{
                    result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                }catch{
                    result = nil
                    print("Couldn't parse data")
                    self.imageLabel.text = "Error: Couldn't parse the data"
                    return
                }
                 print (result)
                guard let photosDictionary = result["photos"] as? NSDictionary else {
                    print ("no photos in query")
                    self.imageLabel.text = "Error: No photos in query"
                    return;
                }
                guard let totalPages = photosDictionary["pages"] as? Int else{
                    print ("Couldn't extract total pages")
                    self.imageLabel.text = "Error: Couldn't extract total pages"
                    return
                }
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit)))
                self.getImageFromRandomPage(methodArguments, pageNumber: randomPage)
                /*guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else{
                    print ("no photos in query")
                    return;
                }
                if (totalPhotos>0){
                    guard let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print ("no photos in query")
                        return;
                    }
                    
                    
                    
                    let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                    let photoDictionary = photoArray[randomIndex] as [String: AnyObject]
                    print (photoArray[randomIndex])
                    let photoTitle = photoDictionary["title"] as? String
                    
                    guard let imageURLString = photoDictionary["url_m"] as? String else {
                        print("photo doesn't have an url")
                        return
                    }
                    
                    let imageURL = NSURL(string: imageURLString)
                    
                    guard let imageData = NSData(contentsOfURL: imageURL!) else {
                        print("image doesn't exist")
                        dispatch_async(dispatch_get_main_queue(), {
                            //show the image in the main thread
                            print("image doesn't exist")
                        })
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        //show the image in the main thread
                        self.searchedImage.image = UIImage(data: imageData)
                        self.imageLabel.text = photoTitle
                    })
                    
                    
                }*/
                
            }
            task.resume()
            
           
            
        }
    }
    
    func getImageFromRandomPage (methodArgs: [String : AnyObject], pageNumber : Int) {
        var withPageDictioanry = methodArgs
        withPageDictioanry["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapeParameters(withPageDictioanry)
        let url = NSURL (string: urlString)!
        
        let request = NSURLRequest (URL: url)
        
        let task = session.dataTaskWithRequest(request){ (data, response, error) in
            guard (error == nil) else{
                print("error with getting task")
                self.imageLabel.text = "Error: Server error"
                return
            }
            guard let data = data else {
                print ("No data!!!")
                self.imageLabel.text = "Error: No data"
                return
            }
            
            let result: AnyObject!
            do{
                result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            }catch{
                result = nil
                print("Couldn't parse data")
                self.imageLabel.text = "Error: Couldn't parse data"
                return
            }
            print (result)
            guard let photosDictionary = result["photos"] as? NSDictionary else {
                print ("no photos in query")
                self.imageLabel.text = "Error: No photos in query"
                return;
            }
            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else{
                print ("no photos in query")
                self.imageLabel.text = "Error: No photos in query"
                return;
            }
            if (totalPhotos>0){
                guard let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print ("no photos in query")
                    self.imageLabel.text = "Error: No photos in query"
                    return;
                }
                
                
                
                let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                let photoDictionary = photoArray[randomIndex] as [String: AnyObject]
                print (photoArray[randomIndex])
                let photoTitle = photoDictionary["title"] as? String
                
                guard let imageURLString = photoDictionary["url_m"] as? String else {
                    print("photo doesn't have an url")
                    self.imageLabel.text = "Error: Photo doesn't have url"
                    return
                }
                
                let imageURL = NSURL(string: imageURLString)
                
                guard let imageData = NSData(contentsOfURL: imageURL!) else {
                    print("image doesn't exist")
                    dispatch_async(dispatch_get_main_queue(), {
                        //show the image in the main thread
                        print("image doesn't exist")
                        self.imageLabel.text = "Error: Image doesn't exust"
                    })
                    return
                }
                dispatch_async(dispatch_get_main_queue(), {
                    //show the image in the main thread
                    self.searchedImage.image = UIImage(data: imageData)
                    self.imageLabel.text = photoTitle
                })
                
                
            }
            
        }
        task.resume()
        
    }
    
    func addKeyboardDismissRecognizer() {
        self.view.addGestureRecognizer(tap!)
    }
    
    func removeKeyboardDismissRecognizer() {
        self.view.removeGestureRecognizer(tap!)
        
    }
    func DismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    /*keyboard and text delegates will be here*/
    func keyboardShow(notification:NSNotification) {
        if( !keyboardShowed){
            self.view.frame.origin.y -=  getKeyboardHeight(notification)
            keyboardShowed = true
        }
        
    }
    func keyboardHide(notification:NSNotification) {
        self.view.frame.origin.y +=  getKeyboardHeight(notification)
        keyboardShowed = false
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat{
        let info = notification.userInfo
        let keyboardSize = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    
    }
    func subscribeToKeyboardNotification () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func unsubscribeToKeyboardNotification() {
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIKeyboardWillHideNotification, object: nil)
    }
    /*end of delegates*/
    
    /*check is empty or contain only spaces*/
    
    func isEmpty(text: String) -> Bool {
    
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        print(trimmed.isEmpty)
        return !trimmed.isEmpty
        

    }
    /*check long and lat textfields
    TODO: accept only numbers*/
    func checkLongAndLatContainNoErrors () -> Bool {
        guard let longTextField = longitude?.text else {
            print("long failure 1")
            imageLabel.text = "Error: No text?"
            return false
        }
        guard isEmpty(longTextField) else{
            print("long failure 1 empty")
            imageLabel.text = "Error: Empty long value"
            return false
        }
        guard let latTextField = latitude?.text else {
            print("lat failure 1")
            imageLabel.text = "Error: No text?"
            return false
        }
        guard isEmpty(latTextField) else{
            print("lat failure 1 empty")
            print("do error handling \(latTextField)")
            imageLabel.text = "Error: Empty field"
            return false
        }
        //Probably dont|'t even have to write it like this
        
        
        guard ((longTextField.floatValue != nil) && (latTextField.floatValue != nil)) else{
            print("not a number")
            imageLabel.text = "Error, you didn't enter an int"
            return false
        }
        
        let longInt:Float? = (longTextField as NSString).floatValue
        let latInt:Float? = (latTextField as NSString).floatValue
        
       
        
        if((longInt <= 180 && longInt >= -180) && ((latInt <= 90 && latInt >= -90))){
            return true
        }
        print("error thrown here\(longInt) \(latInt)")
        imageLabel.text = "Longitude must be between -180 and 180 and latitude must be between -90 and 90"
        //throw error
        return false;
    }
    
    /*escape parameters*/
    
    func escapeParameters(parameters : [String : AnyObject]) -> String {
        var urlVars = [String] ()
        for (key, value) in parameters{
            let stringValue = "\(value)" //is it a String?
            
            let escape = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escape!)"]
            
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func getBbox(long: String, lat:String) -> String {
        //minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude.
       // return "-122.412, 37.773779,-122.412,37.773779"
        let longitude: Float? = (long as NSString).floatValue
        let latitude: Float? = (lat as NSString).floatValue
        //want the max minimum value to be the bottom left
        let bottomLeftLon = max(longitude! - BOUNDING_BOX_WIDTH, LON_MIN)
        let bottomLeftLat = max(latitude! - BOUNDING_BOX_WIDTH, LAT_MIN)
        //want the min max value to be the top
        let topRightLon = min (longitude! + BOUNDING_BOX_WIDTH, LON_MAX)
        let topRightLat = min (latitude! + BOUNDING_BOX_HEIGHT, LAT_MAX)
        return "\(bottomLeftLon),\(bottomLeftLat),\(topRightLon),\(topRightLat)"
    }
    

}

