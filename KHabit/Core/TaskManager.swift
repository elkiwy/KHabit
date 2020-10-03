//
//  TaskManager.swift
//  KHabit
//
//  Created by Stefano Bertoli on 16/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import Foundation
import CoreData
import UIKit


///Helper structure for Stats page
struct TaskCompletionStat {
    let task:CDTask
    let count:Int
}



///Main class for handling Tasks
class TaskManager:ObservableObject{
    ///Singleton shared instance
    static let shared = TaskManager()
    
    ///Main tasks list
    @Published var tasks:[CDTask] = []
    
    ///Main CoreData context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    ///Singleton private initializer
    private init() {
        //Setup context to automatically updates itself when it sees a change
        context.automaticallyMergesChangesFromParent = true

        //Load all the saved tasks from Database
        self.loadTasks()
    }
    
    
    //MARK: Graphs Data
    ///Retrieve data for the weekday graph
    func getWeekdayStats()->[Day:Int]{
        var data:[Day:Int] = [ .mon : 0, .tue : 0, .wed : 0, .thu : 0, .fri : 0, .sat : 0, .sun : 0 ]
        let request:NSFetchRequest<CDTaskCompletion> = CDTaskCompletion.fetchRequest()
        do{
            let cal = Calendar.current
            let completions = try context.fetch(request)
            for completion in completions{
                let weekday = cal.component(.weekday, from: completion.date!)
                switch weekday {
                case 1: data[.sun]! += 1; break;
                case 2: data[.mon]! += 1; break;
                case 3: data[.tue]! += 1; break;
                case 4: data[.wed]! += 1; break;
                case 5: data[.thu]! += 1; break;
                case 6: data[.fri]! += 1; break;
                case 7: data[.sat]! += 1; break;
                default: print("Wut?");
                }
            }
        }catch{
            print("[DB] Couldn't not fetch \(error)")
        }
        
        return data
    }

    
    
    ///Retrieve data for completions graph
    func getTaskCompletionsStats()->[TaskCompletionStat]{
        var data:[TaskCompletionStat] = []
        for t in self.tasks {
            data.append(TaskCompletionStat(task: t, count: t.history?.allObjects.count ?? 0))
        }
        data.sort { (a, b) -> Bool in return a.count > b.count }
        return data
    }

    
    //MARK: Utility
    ///Provide a dummy task list
    func getTestData() -> [CDTask]{
        
        var data:[CDTask] = []
        let t1 = CDTask.dummy(context: self.context, id: "test1", name: "Learn something interesting", desc: "Anything, really")
        t1.reminderEnabled = true
        data.append(t1)

        let t = CDTask.dummy(context: self.context, id: "test2", name: "Learn Japanese", desc: "Anki decks daily")
        t.history?.adding(CDTaskCompletion.dummy(context: self.context, date: Date(), note: "oggi", task: t))
        t.history?.adding(CDTaskCompletion.dummy(context: self.context, date: Date().addingTimeInterval(-1*24*60*60), note: "l'altro ieri", task: t))
        t.history?.adding(CDTaskCompletion.dummy(context: self.context, date: Date().advanced(by: -1000000), note: "passato", task: t))
        t.reminderEnabled = true
        data.append(t)
        
        let t2 = CDTask.dummy(context: self.context, id: "test3", name: "Exercise", desc: "Workout or anything good for your body")
        t2.history?.adding(CDTaskCompletion.dummy(context: self.context, date: Date(), note: "oggi altro", task: t2))
        data.append(t2)
        data.append(CDTask.dummy(context: self.context, id: "test4", name: "Eat a fruit", desc: ""))
        return data
    }
    
    
    //MARK: Task handling
    ///Add a new task to the list
    func newTask(name:String, desc:String? = nil)->CDTask{
        //Create the unique id
        let id = "\(name)_\(Int.random(in: 100000...999999))"

        //Create task entity
        let task = CDTask(context: context)
        task.id = id
        task.name = name
        task.desc = desc
        task.reminderEnabled = false
        task.reminderTimeH = Int16(0)
        task.reminderTimeM = Int16(0)
        task.weekMask = Int16(0b1111111)
        self.tasks.append(task)
        
        //Save it to database
        do { try context.save(); print("[DB] Task saved to db") } catch{ fatalError("[DB] Cose andate male \(error)") }
        return task
    }
   
    
    
    ///Return all the task completed on a specific date
    func tasksCompleted(atDate d:Date?)->[CDTaskCompletion]{
        if d==nil{return []}
        var completions:[CDTaskCompletion] = []
        for task in self.tasks{
            if let compl = task.completionAtDate(d!){
                completions.append(compl)
            }
        }
        return completions
    }

    
    
    ///Fetch tasks saved into CoreData
    func loadTasks(){
        let request:NSFetchRequest<CDTask> = CDTask.fetchRequest()
        do{
            self.tasks = try context.fetch(request)
            print("[DB] Loaded \(self.tasks.count) tasks")
        }catch{
            print("[DB] Couldn't not fetch \(error)")
        }
    }
    

    
    ///Delete a Task
    func deleteTask(task:CDTask){
        do{
            //Remove all the reminders for this task
            task.clearMyReminders()
            
            //Find its index
            var index = -1;
            for i in 0...tasks.count-1{
                if task.id == tasks[i].id{
                    index = i
                }
            }
            
            //Delete it from database
            if index > -1{
                self.tasks.remove(at: index)
                context.delete(task)
            }

            //Save its context
            print("[DB] Delete task: \(task.id ?? "NO_ID")")
            try context.save()
            
        }catch{
            print("[DB] Couldn't not delete task: \(error)")
        }
    }
    
    
    
    ///Deletes all the tasks in CoreData
    func deleteTasks(){
        do{
            for task in self.tasks{
                context.delete(task)
                print("[DB] Delete task: \(task.id ?? "NO_ID")")
            }
            try context.save()
            
        }catch{
            print("[DB] Couldn't not fetch \(error)")
        }
    }
    
}
