//
//  NewTask.swift
//  KHabit
//
//  Created by Stefano Bertoli on 19/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI


extension ForEach where Data.Element: Hashable, ID == Data.Element, Content: View {
    init(values: Data, content: @escaping (Data.Element) -> Content) {
        self.init(values, id: \.self, content: content)
    }
}




struct NewTask:View{
    //States
    @Binding var visible:Bool
    @State var name:String = ""
    @State var desc:String = ""
    @State var weekMask:Int = 0b1111111
    @State var showNameRequired = false
    @State var reminderEnabled = false
    @State var reminderSel = ["00", "00"]
    
    //Constants
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView{
            VStack{
                List() {
                    //Name section
                    Section(header: Text("Name")) {
                        RowField(name: "Name", text: self.$name)
                            .background(self.showNameRequired ? Color.red : Color.clear)
                    }
                    
                    //Description section
                    Section(header: Text("Description")) {
                        RowField(name: "Description", text: self.$desc)
                    }
             
                    //Reminders section
                    Section(header: Text("Reminder")) {
                        Toggle(isOn: self.$reminderEnabled) {
                            Text("Enabled").bold()
                        }.onTapGesture {
                        }.toggleStyle(SwitchToggleStyle(tint: self.colorScheme == .dark ? accDark : accLight))
                        if self.reminderEnabled{
                            NavigationLink(destination:SelectWeekly(bind: self.$weekMask)){
                                RowSetting(label: "Weekly Schedule", value: "\(countOnes(binary: Int16(self.weekMask)))")
                            }
                            NavigationLink(destination:SelectTime(selection: self.$reminderSel, action: {
                            })){
                                RowSetting(label: "Remind me at", value: "\(self.reminderSel.first!):\(self.reminderSel.last!)")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel"){
                    self.visible = false
                },
                trailing: Button("Save"){
                    if self.name.count > 0{
                        let task = TaskManager.shared.newTask(name: self.name, desc: self.desc)
                        task.weekMask = Int16(self.weekMask)
                        task.reminderEnabled = self.reminderEnabled
                        task.reminderTimeH = Int16(self.reminderSel.first!)!
                        task.reminderTimeM = Int16(self.reminderSel.last!)!
                        task.updateReminders()
                        task.cd_sync()
                        self.visible = false
                    }else{
                        self.showNameRequired = true
                    }
                }
            )
        }
        .accentColor(self.colorScheme == .dark ? accDark : accLight)
    }
}



#if DEBUG
struct NewTask_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            NewTask(visible: Binding.constant(true)) .colorScheme(.dark)
            EditTask(task: testData())
            NewTask(visible: Binding.constant(true))
                .colorScheme(.light)
        }
    }
}
#endif
