//
//  ContentView.swift
//  KHabit Watch Extension
//
//  Created by Stefano Bertoli on 26/09/20.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI
import CoreData


let accLight = Color(red: 88/255, green: 86/255, blue: 214/255)
let accDark = Color(red: 94/255, green: 92/255, blue: 230/255)

class TaskManager_Watch:ObservableObject {
    @Published var tasks:[CDTask] = []

    var context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext

    static let shared = TaskManager_Watch()
    
    private init(){
        self.loadTasks()
    }

    ///Loads tasks saved into CoreData
    func loadTasks(){
        let request:NSFetchRequest<CDTask> = CDTask.fetchRequest()
        do{
            context.automaticallyMergesChangesFromParent = true
            self.tasks = try context.fetch(request)
            print("[DB] Loaded \(self.tasks.count) tasks")
        }catch{
            print("[DB] Couldn't not fetch \(error)")
        }
    }
    
    
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
    
}




struct TaskCell:View{
    @ObservedObject var task:CDTask
    @Environment(\.colorScheme) var cs

    var body: some View{
        return Button(action:{
            WKInterfaceDevice.current().play(.success)
            if self.task.doneToday(){
                self.task.deleteForToday()
            }else{
                self.task.completeForToday()
            }
        }) {
            HStack{
                ZStack{
                    Image(systemName: "circle.fill")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(self.task.doneToday() ? (cs == .dark ? accDark : accLight) : .clear)
                    Image(systemName: self.task.doneToday() ? "checkmark.circle.fill" : "circle")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(cs == .dark ? .white : .black)
                }
                
                Text("\(self.task.name!)")
            }
        }
    }
}



struct ContentView: View {
    @ObservedObject var manager:TaskManager_Watch = TaskManager_Watch.shared

    @ViewBuilder
    var body: some View {
        VStack{
            List{
                if self.manager.tasks.count > 0 {
                    ForEach(self.manager.tasks.indices){ i in
                        TaskCell(task: self.manager.tasks[i])
                    }
                }else{
                    Text("No task available, please create some using the app on your phone.")
                }
            }
        }
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
