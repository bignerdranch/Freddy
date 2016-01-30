//
//  AppDelegate.swift
//  ProfilingHarness
//
//  Created by Zachary Waldowski on 1/3/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Cocoa
import Freddy

func afterDelay(delay: NSTimeInterval, upon queue: dispatch_queue_t = dispatch_get_main_queue(), perform: () -> ()) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(delay, queue, perform)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            let testBundle = NSBundle.mainBundle()
            guard let data = testBundle.URLForResource("AllSetsArray", withExtension: "json", subdirectory: "Benchmark").flatMap(NSData.init) else {
                print("Could not read stress test data from test bundle")
                return
            }

            let json: JSON
            do {
                json = try JSON(data: data, usingParser: JSONParser.self)
            } catch {
                print("Could not parse JSON data")
                return
            }

            let objects: [CardSet]
            do {
                objects = try json.arrayOf(type: CardSet.self)
            } catch {
                print("Could not deserialize JSON")
                return
            }
            print("Parsed!")

            afterDelay(1.5) {
                print("Artificially extending the lifetime of \(objects.count) instances of \(CardSet.self)")
            }
        }
    }

}

