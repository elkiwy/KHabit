//
//  CoreDataObjects.swift
//  KHabit
//
//  Created by Stefano Bertoli on 26/09/20.
//  Copyright © 2020 elkiwy. All rights reserved.
//


import Foundation
import CoreData
import UIKit

/*
 NB: This file is shared between iOS app and Watch app.
     For platform specific code here use "#if os(iOS/WatchOS) ... #endif"
 */



//MARK: Notifications - Reminders
#if os(iOS)
///Debug method to print all the pending notificaitons
func listPendingNotifications(){
    UNUserNotificationCenter.current().getPendingNotificationRequests { (notifications) in
        var i=1
        for noti in notifications{
            print("\(noti.identifier): \(String(describing: noti.trigger)) \(noti.content.title)")
            i+=1
        }
    }
}
#endif

///Convert a single mask number to an array of days from the mask.
func maskToWeekdays(mask:Int)->[Int]{
    var weekdays:[Int] = []
    if (mask & (0b1 << 0)) > 0 {weekdays.append(0)}
    if (mask & (0b1 << 1)) > 0 {weekdays.append(1)}
    if (mask & (0b1 << 2)) > 0 {weekdays.append(2)}
    if (mask & (0b1 << 3)) > 0 {weekdays.append(3)}
    if (mask & (0b1 << 4)) > 0 {weekdays.append(4)}
    if (mask & (0b1 << 5)) > 0 {weekdays.append(5)}
    if (mask & (0b1 << 6)) > 0 {weekdays.append(6)}
    return weekdays
}

///Convert my day to iOS weekday (weekdays = starts with sunday at 1, mydays = starts with monday at 0)
func dayToWeekday(_ d:Int)->Int{
    return ((d + 1) % 7) + 1
}




//MARK: CDTaskCompletion Extension
///Add functionality to the CoreData object
extension CDTaskCompletion{
    ///Handy method to create a dummy object
    static func dummy(context:NSManagedObjectContext, date:Date, note: String?, task: CDTask)->CDTaskCompletion{
        let c = CDTaskCompletion(context: context)
        c.date = date
        c.note = note ?? ""
        c.task = task
        return c
    }
    
    ///Tells if this completion is in the same day as another date
    func sameDayAs(date:Date)->Bool{
        return Calendar.current.isDate(self.date!, inSameDayAs: date)
    }

    ///Updates the note attached to this completion
    func updateNote(note: String){
        self.note = note
        do{ try self.managedObjectContext?.save(); print("[DB] Completion updated")} catch{fatalError("Something wrong \(error)")}
    }
}






//MARK: CDTask Extension
///Add functionality to the CoreData object
extension CDTask{
    ///Handy method to create a dummy object
    static func dummy(context:NSManagedObjectContext, id:String, name:String, desc:String)->CDTask{
        let t = CDTask(context: context)
        t.id = id
        t.name = name
        t.desc = desc
        return t
    }
    
    
    
    
    
    ///Retrieve the task completion object for a specific date for this task
    func completionAtDate(_ date:Date)->CDTaskCompletion?{
        for completion in (history?.allObjects as! [CDTaskCompletion]){
            if (completion.sameDayAs(date: date)){
                return completion
            }
        }
        return nil
    }
    
    ///Checks if this task has been completed on a certain date
    func doneAtDate(_ date:Date)->Bool{
        if let h = self.history{
            return (h.allObjects as! [CDTaskCompletion]).contains { (completion) -> Bool in return completion.sameDayAs(date: date)}
        }else{
            return false
        }
    }

    ///Checks if this task has been completed today
    func doneToday()->Bool{
        return self.doneAtDate(Date())
    }
    
    ///Complete this task for this date
    func completeFor(date: Date, withNote note:String? = nil){
        if self.doneAtDate(date)==false{
            //Add the new CDTaskCompletion
            let completionEntity = CDTaskCompletion(context: self.managedObjectContext!)
            completionEntity.date = date
            completionEntity.note = note ?? ""
            completionEntity.task = self
            self.history?.adding(completionEntity)
            
            //Save it to Database
            do { try self.managedObjectContext?.save(); print("[DB] Completion save to db") } catch{ fatalError("[DB] Something wrong \(error)") }
        }
    }
    
    ///Complete this task for today
    func completeForToday(){
        self.completeFor(date: Date())
    }
        
    
    
    ///Deletes this task for this date
    func deleteFor(date: Date){
        if let completion = self.completionAtDate(date){
            self.managedObjectContext?.delete(completion)
            do { try self.managedObjectContext?.save(); print("[DB] Completion removed from db") } catch{ fatalError("[DB] Something wrong \(error)") }
        }
    }
    
    ///Deletes this task for today
    func deleteForToday(){
        self.deleteFor(date: Date())
    }
    
    ///Syncs this object to Database
    func cd_sync(){
        do { try self.managedObjectContext?.save(); print("[DB] task \"\(self.name ?? "")\" synced to db") } catch{ fatalError("[DB] Something wrong \(error)") }
    }
    
    
    
    
    
    
    //MARK: Reminders
    #if os(iOS)
    ///Clear all the reminders for this task
    func clearMyReminders(){
        //Clear all the previous scheduled notifications for this task
        let identifiers = [1,2,3,4,5,6,7].map { (weekday) -> String in notificationIdentifierForWeekday(weekday: weekday) }
        print("clearing notifications for \(identifiers)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    ///Create the notification identifier for a specific weekday
    private func notificationIdentifierForWeekday(weekday:Int)->String{
        return "\(self.id!)_\(weekday)"
    }
    
    ///Create the reminder content
    func makeReminder() -> UNMutableNotificationContent{
        let content = UNMutableNotificationContent()
        content.title = self.name!
        content.subtitle = self.desc ?? ""
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = const_reminder
        content.userInfo = ["type": const_reminder, "taskId":self.id!]
        return content
    }

    ///Schedule the reminder based on this task properties
    func updateReminders(minOfDelay:Int = 0){
        //Check for permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (success, err) in
            if let err=err{ print("Couldn't activate authorization for notifications " + err.localizedDescription) }
        }

        //Clear all the previous scheduled notifications for this task
        self.clearMyReminders()
        
        //Schedule reminder
        if self.reminderEnabled{
            for day in maskToWeekdays(mask: Int(self.weekMask)){
                let content = self.makeReminder()
                let weekday = dayToWeekday(day)
                var dateComps = DateComponents()
                dateComps.hour = Int(self.reminderTimeH) + Int(floor(Double(minOfDelay) / 60))
                dateComps.minute = (Int(self.reminderTimeM) + minOfDelay) % 60
                dateComps.weekday = weekday //weekdays = sunday at 1, mydays = monday at 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: true)
                let request = UNNotificationRequest(identifier: notificationIdentifierForWeekday(weekday: weekday) , content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
                print("Scheduled notification for \(dateComps)")
            }
        }
    }
    
    ///Debug utility function to manually trigger a reminder
    func triggerReminder(secOfDelay:TimeInterval = 1){
        //Check for permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (success, err) in
            if let err=err{ print("Couldn't activate authorization for notifications " + err.localizedDescription) }
        }

        let content = self.makeReminder()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(secOfDelay))
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        let request = UNNotificationRequest(identifier: "manual" , content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("Scheduled manual norification for \(comp)")
    }
    #endif

}

