//
//  ContentView.swift
//  KHabit
//
//  Created by Stefano Bertoli on 16/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI




///Single cell for the Task list
struct TaskCell: View {
    //States
    @ObservedObject var task:CDTask
    @Binding var editMode:Bool
    @State var noteText:String
    @State var writingNote:Bool = false
    @State private var anim : CGFloat = 0.6

    //Costants
    @Environment(\.colorScheme) var colorScheme
    let maxAnim:CGFloat = 1.5

    ///Custom initializer
    init(task:CDTask, editMode:Binding<Bool>) {
        self.task = task
        _editMode = editMode
        let note = task.completionAtDate(Date())?.note ?? ""
        _noteText = State(initialValue: note)
    }
    
    @ViewBuilder
    var body: some View {
        HStack{
            //Checkbox element
            Checkbox(task: task) {
                if self.task.doneToday(){self.task.deleteForToday()
                }else{ self.task.completeForToday() }
                
                self.anim = self.task.doneToday() ? self.maxAnim : 0.55
            }.overlay(
                Circle()
                    .stroke(accDark, lineWidth: 2)
                    .scaleEffect(anim)
                    .opacity(Double(self.maxAnim - anim))
                    .animation(Animation.easeInOut(duration: 0.5))
            )
            
            //Name and Description
            VStack(alignment: .leading){
                Text(task.name ?? "ERROR").font(.headline)
                    .opacity(self.editMode ? 0.5 : 1)
                Text(task.desc ?? "ERROR").font(.subheadline).foregroundColor(Color.gray)
            }
            Spacer()
            
            //Note button
            Button(action: {self.writingNote = true}) {
                IconImage(name: "square.and.pencil", size: 24)
                    .offset(y:-3)
            }
            .opacity(self.task.doneToday() ? 1 : 0)
            .buttonStyle(BorderlessButtonStyle())
        }
        //Extra sheet to write a note on a completion
        .sheet(isPresented: self.$writingNote) {
            NavigationView{
                VStack{
                    //Description
                    Text("Add a note to describe how you completed the task \""+self.task.name!+"\" today.")
                        .font(.caption)
                    Divider()
                    
                    //Note Text field
                    CustomTextField(text: self.$noteText, isResponder: Binding.constant(true))
                        .frame(maxHeight: 100)
                        .padding()
                        .navigationBarTitle("Add a note")
                    Spacer()
                    
                    //Save button
                    Button(action: {
                        self.task.completionAtDate(Date())?.updateNote(note: self.noteText)
                        self.writingNote = false
                    }) {
                        Text("Save")
                            .font(.headline)
                            .frame(maxWidth:.infinity, minHeight: 48)
                            .background(self.colorScheme == .dark ? accDark : accLight)
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
        }
        
    }
}


///Main task list view
struct TaskListView: View {
    //States
    @ObservedObject var manager = TaskManager.shared
    @State var editMode:Bool = false
    @State private var selection = 0
    @State private var newTaskSheet = false
    
    //Constants
    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder
    var body: some View {
        //Main tab view
        TabView(selection: $selection){
            //View container
            NavigationView{
                //Task List
                VStack{
                if (manager.tasks.count>0){
                    List{
                        ForEach(manager.tasks, id: \.self) { task in
                            //Task cell for edit mode
                            if self.editMode{
                                NavigationLink(destination: NavigationLazyView(EditTask(task: task))){
                                    TaskCell(task: task, editMode:self.$editMode)
                                }
                                //Task cell for normal mode
                            }else{
                                TaskCell(task: task, editMode:self.$editMode)
                            }
                        }
                        .onDelete(perform: { indexSet in
                            TaskManager.shared.deleteTask(task: TaskManager.shared.tasks[indexSet.first!])
                        })
                    }
                    .listStyle(PlainListStyle())
                }else{
                    Text("Create you first Task by tapping the \"+\" icon on the top right of the screen.")
                        .padding(32)
                }
                }
                
                //View Title
                .navigationBarTitle("Tasks")
                
                //View toolbar
                .toolbar(content: {
                    //New task button
                    ToolbarItem(placement: .primaryAction ){
                        Button(action:{
                            self.newTaskSheet = true
                        }){Image(systemName: "plus")}
                    }
                    //Edit task button
                    ToolbarItem(placement: .cancellationAction){
                        Button(self.editMode ? "Done" : "Edit"){
                            self.editMode.toggle()
                        }
                    }
                })
            }
            .tabItem {
                VStack {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
            }
            .tag(0)
            
            
            //Second Tab item
            NavigationView{
                HistoryView()
                    .font(.title)
            }
            .tabItem {
                VStack {
                    Image(systemName: "calendar")
                    Text("History")
                }
            }
            .tag(1)
            
            
            //Third Tab item
            NavigationView{
                StatsView()
                    .font(.title)
            }
            .tabItem {
                VStack {
                    Image(systemName: "sparkles")
                    Text("Stats")
                }
            }
            .tag(2)
        }
        .accentColor(self.colorScheme == .dark ? accDark : accLight)
        .sheet(isPresented: $newTaskSheet) {
            NewTask(visible: self.$newTaskSheet)
        }
    }
}






#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TaskManager.shared.tasks = TaskManager.shared.getTestData()
        return Group{
            TaskListView().colorScheme(.dark)
        }
    }
}
#endif
