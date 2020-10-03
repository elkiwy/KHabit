//
//  AppDelegate.swift
//  KHabit
//
//  Created by Stefano Bertoli on 16/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity

let const_complete = "complete"
let const_delay1h = "delay1h"
let const_delay30m = "delay30m"
let const_reminder = "reminder"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /* Unused WatchConnectivity API
    var session: WCSession? = nil
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session changed to state \(activationState.rawValue)")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session inactive")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received message \(message)")
    }
    */
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Initialize Task manager
        let _ = TaskManager.shared
        
        //Register notifications actions
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let complete = UNNotificationAction(identifier: const_complete, title: "Mark complete", options: [])
        let delay1h = UNNotificationAction(identifier: const_delay1h, title: "Remind me in 1 hour", options: [])
        let delay30m = UNNotificationAction(identifier: const_delay30m, title: "Remind me in 30 minutes", options: [])
        let category = UNNotificationCategory(identifier: const_reminder, actions: [complete, delay30m, delay1h], intentIdentifiers: [])
        center.setNotificationCategories([category])
        
        /* Unused WatchConnectivity API
        if WCSession.isSupported(){
            self.session = WCSession.default
            self.session?.delegate = self
            self.session?.activate()
        }*/
        
        return true
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String {
            print("Custom data received: \(type)")

            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // the user swiped to unlock
                print("Default identifier")

            //Mark as complete
            case const_complete:
                if let taskId = userInfo["taskId"] as? String{
                    let task = TaskManager.shared.tasks.first { (t) -> Bool in return t.id == taskId}
                    task?.completeForToday()
                }
                
            //Remind me in 30 minutes
            case const_delay30m:
                if let taskId = userInfo["taskId"] as? String{
                    let task = TaskManager.shared.tasks.first { (t) -> Bool in return t.id == taskId}
                    task?.updateReminders(minOfDelay: 2)
                }

            //Remind me in an hour
            case const_delay1h:
                if let taskId = userInfo["taskId"] as? String{
                    let task = TaskManager.shared.tasks.first { (t) -> Bool in return t.id == taskId}
                    task?.updateReminders(minOfDelay: 60)
                }

            default:
                break
            }
        }

        // you must call the completion handler when you're done
        completionHandler()
    }
    
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .badge, .sound])
    }
    
    
    
    
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    
    
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "KHabit")
        
        /* Unused Listener for db updates
        guard let desc = container.persistentStoreDescriptions.first else{fatalError("No descriptions found")}
        desc.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)*/
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        /* Unused Listener for db updates
        NotificationCenter.default.addObserver(self, selector: #selector(databaseChanged), name: .NSPersistentStoreRemoteChange, object: nil)*/

        return container
    }()

    
    
    /* Unused Listener for db updates
    @objc func databaseChanged(){
        DispatchQueue.main.async {
            TaskManager.shared.loadTasks()
        }
    }*/
    
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


