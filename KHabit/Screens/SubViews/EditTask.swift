//
//  EditTask.swift
//  KHabit
//
//  Created by Stefano Bertoli on 22/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI

///Time selector view
struct SelectTime: View  {
    //States
    @Binding var selection: [String]
    var action:()->() = {}

    //Constants
    let data: [(String, [String])] = [
        ("One", Array(0...23).map { "\(String(format: "%02d", $0))" }),
        ("Two", Array(0...11).map { "\(String(format: "%02d", $0*5))" })
    ]


    var body: some View {
        VStack{
            //Info text
            Text("Select a time on which you want to be notified for this task.")
                .lineLimit(10)
                .font(.body)
                .padding()
            
            GeometryReader { geometry in
                HStack {
                    ForEach(0..<self.data.count) { column in
                        VStack{
                            Spacer()
                            Text(column == 0 ? "Hours" : "Minutes") .font(.headline)
                            Picker(self.data[column].0, selection: self.$selection[column]) {
                                ForEach(0..<self.data[column].1.count) { row in
                                    Text(verbatim: self.data[column].1[row])
                                        .tag(self.data[column].1[row])
                                }
                            }
                            //.pickerStyle(PopUpButtonPickerStyle())
                            .frame(width: geometry.size.width / 2)
                            .clipped()
                            Spacer()
                        }
                    }
                }.onDisappear {
                    self.action()
                }
            }
            .navigationTitle("Reminder")
        }
    }
}

///Count how many ones are in a bitmask
func countOnes(binary:Int16)->Int{
    var count = 0
    var tmp = binary
    while(tmp != 0){
      tmp = tmp & (tmp - 1);
      count += 1
    }
    return count
}


///Edit task view
struct EditTask:View{
    //States
    @ObservedObject var task:CDTask
    @State var showNameRequired:Bool = false
    @State var name: String = "DEFAULT"
    @State var desc: String = ""
    @State var weekMask: Int = 0b0
    @State var reminderEnabled: Bool = true
    @State var reminderSel = ["00", "00"]

    //Constants
    @Environment(\.colorScheme) var colorScheme

    init(task:CDTask) {
        self.task = task
        _name = State(initialValue: task.name!)
        _desc = State(initialValue: task.desc ?? "")
        _weekMask = State(initialValue: Int(task.weekMask))
        _reminderEnabled = State(initialValue: task.reminderEnabled)
        _reminderSel = State(initialValue: [String(format: "%02d", task.reminderTimeH), String(format: "%02d", task.reminderTimeM)] )
        UISwitch.appearance().onTintColor = (colorScheme == .dark ? accDark.uiColor() : accLight.uiColor())
    }
        

    var body: some View{
        //Utility bind to listen for name changes and sync task
        let nameBind = Binding<String>(get: { self.name }, set: { self.name = $0
            self.task.name = self.name
            self.task.cd_sync()
        })

        //Utility bind to listen for descriptions changes and sync task
        let descBind = Binding<String>(get: { self.desc }, set: { self.desc = $0
            self.task.desc = self.desc
            self.task.cd_sync()
        })
        
        //Actual body
        VStack{
            List() {
                //Name section
                Section(header: Text("Name")) {
                    RowField(name: "Name", text: nameBind).background(self.showNameRequired ? Color.red : Color.clear)
                }
                
                //Description section
                Section(header: Text("Description")) {
                    RowField(name: "Description", text: descBind)
                }
                    
                //Reminders section
                Section(header: Text("Reminder")) {
                    Toggle(isOn: self.$reminderEnabled) {
                        Text("Enabled").bold()
                    }.onTapGesture {
                        self.task.reminderEnabled = !self.reminderEnabled
                        self.task.updateReminders()
                        self.task.cd_sync()
                    }.toggleStyle(SwitchToggleStyle(tint: self.colorScheme == .dark ? accDark : accLight))
                    if self.reminderEnabled{
                        NavigationLink(destination:SelectWeekly(bind: self.$weekMask, action: {
                            self.task.weekMask = Int16(self.weekMask)
                            self.task.updateReminders()
                            self.task.cd_sync()
                        })){
                            RowSetting(label: "Weekly Schedule", value: "\(countOnes(binary: self.task.weekMask))")
                        }
                        NavigationLink(destination:SelectTime(selection: self.$reminderSel, action: {
                            self.task.reminderTimeH = Int16(self.reminderSel.first!)!
                            self.task.reminderTimeM = Int16(self.reminderSel.last!)!
                            self.task.updateReminders()
                            self.task.cd_sync()
                        })){
                            RowSetting(label: "Remind me at", value: "\(self.reminderSel.first!):\(self.reminderSel.last!)")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Edit Task")
            .accentColor(self.colorScheme == .dark ? accDark : accLight)
        }
    }
    
}



#if DEBUG
func testData() -> CDTask{
    let t = TaskManager.shared.getTestData()[0]
    t.reminderEnabled = true
    return t
}
struct EditTask_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            EditTask(task: testData())
        }
    }
}
#endif
