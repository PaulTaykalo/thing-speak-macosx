//
//  TSMenulet.swift
//  ThingSpeak
//
//  Created by Paul Taykalo on 12/23/14.
//  Copyright (c) 2014 Stanfy LLC. All rights reserved.
//

import Cocoa
import AppKit

class TSMenulet: NSObject {

    var item : NSStatusItem?
    var shouldTrackWhenOpened = false

    @IBOutlet weak var shouldTrackWhenOpenedItem: NSMenuItem!
    @IBAction func trackWhenOpenedChanged(sender: NSMenuItem) {
        if (sender.state == 0) {
            sender.state = 1
            shouldTrackWhenOpened = true
        } else {
            sender.state = 0;
            shouldTrackWhenOpened = false
        }
    }

    override func awakeFromNib() {
        item = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        let itm = item!
        itm.enabled = true
        itm.highlightMode = true
        itm.toolTip = "There's nothing to see here"
        itm.menu = (NSApplication.sharedApplication().delegate as AppDelegate).mainMenu
        itm.image = NSBundle.mainBundle().imageForResource("yellow-on-16")

        tryToLoadDataOnce()
    }
    

    func tryToLoadDataOnce() {
        let url = NSURL(string:"https://api.thingspeak.com/channels/20910/feeds/last.json?api_key=4KBZITI1B7KSTT8R")!
        let task = NSURLSession.sharedSession().dataTaskWithURL(url)
        {(data, response, error) in

            // We don't care
            if ((error) != nil) {
                self.retryDownload(timeout: 60)
                return
            }
            
            var jsonError: NSError?
            let jsonObject : AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil)
            let jsonDict = jsonObject as NSDictionary
            let fieldValue = jsonDict["field1"]! as NSString
            let createdAt = jsonDict["created_at"]! as NSString
            NSLog("\(jsonObject)")

            dispatch_async(dispatch_get_main_queue()) {
                // update the tool tim
                self.updateItemWithValue(fieldValue, time: createdAt)
                self.retryDownload(timeout: 30)
            }

        }
        task.resume()
    }
    
    func updateItemWithValue(value:NSString, time:NSString) {
        let itm = self.item!
        var openState = "CLOSED"
        if (value.floatValue > 500) {
            itm.image = NSBundle.mainBundle().imageForResource("red-on-16")
        } else {
            itm.image = NSBundle.mainBundle().imageForResource("green-on-16")
            openState = "OPENED"

            if (self.shouldTrackWhenOpened) {
                self.sendOpenedNotification()
                self.shouldTrackWhenOpened = false;
                self.shouldTrackWhenOpenedItem!.state = 0;
            }
        }
        itm.toolTip = "\(openState) at \(time)"


    }
    
    func retryDownload(timeout:Double = 30) {
        delay(timeout, {
            self.tryToLoadDataOnce()
        })
    }

    func sendOpenedNotification() {
        let notification:NSUserNotification = NSUserNotification()
        notification.title = "Hurry! Be the first!"
        notification.informativeText = "Should I show you how to go there on maps?"
        notification.deliveryDate = NSDate().dateByAddingTimeInterval(1)
        notification.soundName = "Submarine"
        notification.setValue(NSBundle.mainBundle().imageForResource("green-on-16"), forKey: "_identityImage")

        NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification);

    }

}
