//
//  AppDelegate.swift
//  fileserver_app
//
//  Created by Johannes Schriewer on 29/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        // switch current directory to user's desktop
        do {
            let home = try NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.DesktopDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false)
            chdir(home.path!)
        } catch {
            print("Could not change working dir")
        }
        
        // print working dir to console
        var cwd = [CChar](count: Int(FILENAME_MAX), repeatedValue: 0)
        getcwd(&cwd, Int(FILENAME_MAX))
        let dirString = String(CString: cwd, encoding: NSUTF8StringEncoding)!
        
        print("Working dir: \(dirString)")
        
        // start server on all interfaces port 4567
        print("Starting server on port 4567...")
        let server = UnchainedFileServer(listenAddress: .Wildcard, port: 4567)
        server.start()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
