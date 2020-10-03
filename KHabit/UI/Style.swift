//
//  Style.swift
//  KHabit
//
//  Created by Stefano Bertoli on 19/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import Foundation
import SwiftUI


let accLight = Color(red: 88/255, green: 86/255, blue: 214/255)
let accDark = Color(red: 94/255, green: 92/255, blue: 230/255)

//MARK: Task Cells
struct Checkbox: View {
    let callback: ()->()
    @ObservedObject var task:CDTask
    @Environment(\.colorScheme) var colorScheme

    init(task: CDTask, callback: @escaping ()->()) {
        self.task = task
        self.callback = callback
    }
    
    var body: some View {
        Button(action:{
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.callback()
        }) {
            ZStack{
                Image(systemName: "circle.fill")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(self.task.doneToday() ? (self.colorScheme == .dark ? accDark : accLight) : .clear)
                Image(systemName: self.task.doneToday() ? "checkmark.circle.fill" : "circle")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: 32, height: 32)
    }
}









struct IconImage: View {
    var name:String
    var size:CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        Image(systemName: name)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width:size, height: size)
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}


struct IconArrow: View {
    var name:String
    var size:CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        IconImage(name: name, size: size)
    }
}




//MARK: Generic row settings



//Button in a row
struct RowSetting: View{
    var label:String
    var value:String
    var action:()->() = {}
    var body: some View{
        Button(action: self.action){
            HStack(){
                Text(self.label)
                    .bold()
                    .allowsHitTesting(false)
                Spacer()
                Text(self.value)
                    .foregroundColor(.gray)
                    .allowsHitTesting(false)
            }
        }
        .frame(height:20)
        .buttonStyle(PlainButtonStyle())
    }
}

//Text field on a row
struct RowField: View{
    var name:String
    @Binding var text:String
    var body: some View{
        TextField(self.name, text: self.$text)
            .padding(.horizontal)
            .frame(height:32.0)
    }
}

//Simple button in a row
struct RowButton: View{
    var label:String
    var current:Bool
    var action:()->()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        HStack{
            Button(action: self.action){
                Text(self.label)
            }
            .foregroundColor(self.colorScheme == .dark ? .white : .black)
            Spacer()
            Image(systemName: "checkmark")
            .opacity(current ? 1 : 0)
                .foregroundColor(self.colorScheme == .dark ? accDark : accLight)
        }
        .padding(.horizontal)
        .frame(height:20.0)
    }
}




enum Day:String {
    case mon = "Monday"
    case tue = "Tuesday"
    case wed = "Wednesday"
    case thu = "Thursday"
    case fri = "Friday"
    case sat = "Saturday"
    case sun = "Sunday"
}
func dayToNum(day:Day)->Int{
    switch day {
    case .mon: return 0
    case .tue: return 1
    case .wed: return 2
    case .thu: return 3
    case .fri: return 4
    case .sat: return 5
    case .sun: return 6
    }
}
func numToDay(num:Int)->Day{
    switch num {
    case 0 : return .mon
    case 1 : return .tue
    case 2 : return .wed
    case 3 : return .thu
    case 4 : return .fri
    case 5 : return .sat
    case 6 : return .sun
    default: return .mon
    }
}




func daySelected(mask:Int, day: Day)->Bool{
    return ((mask >> dayToNum(day: day)) & 0b1) == 1
}

func toggleDay(mask:Int, day: Day)->Int{
    return mask ^ (1 << dayToNum(day: day))
}

struct SelectWeekly:View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var bind:Int
    var action:()->() = {}
    let values:[Day] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
    var body: some View{
        VStack{
            Text("Select the days you want to be reminded during the week for this task")
                .font(.body)
                .padding()
            List{
                ForEach(values:values){ day in
                    RowButton(label: day.rawValue, current: daySelected(mask: bind, day: day), action: {
                        print("old bind \(self.bind)")
                        self.bind = toggleDay(mask: self.bind, day: day)
                        print("new bind \(self.bind)")

                        //self.presentationMode.wrappedValue.dismiss()
                        self.action()
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.white) //Somehow this fixes the offsetting glitch
            .navigationBarTitle("Weekly Schedule")
        }
    }
}

extension Color {
    func uiColor() -> UIColor {
        let components = self.components()
        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {

        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}

#if DEBUG
struct Style_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            TaskListView(editMode: false)
            SelectWeekly(bind: Binding.constant(5))//.colorScheme(.dark)
            //Checkbox(id: "123", checked: true) { (a, b) in }.previewLayout(.fixed(width: 100, height: 100))
            //Checkbox(id: "123", checked: false) { (a, b) in }.previewLayout(.fixed(width: 100, height: 100))
            //Checkbox(id: "123", checked: true) { (a, b) in }.previewLayout(.fixed(width: 100, height: 100)).colorScheme(.dark)
            //Checkbox(id: "123", checked: false) { (a, b) in }.previewLayout(.fixed(width: 100, height: 100)).colorScheme(.dark)
            NewTask(visible: Binding.constant(true)).colorScheme(.dark)
            //NewTask(visible: Binding.constant(true))
            RowButton(label: "test", current: true) { }.previewLayout(.fixed(width: 360, height: 70))
            RowButton(label: "test", current: false) { } .previewLayout(.fixed(width: 360, height: 70))
            //RowSetting(label: "testbutton", value: "Cipolla") .previewLayout(.fixed(width: 360, height: 70))
            //RowSetting(label: "testbutton", value: "Cipolla") .previewLayout(.fixed(width: 360, height: 70))
            //TaskCell(task: TaskManager.getTestData()[0], editMode: Binding.constant(true)) .previewLayout(.fixed(width: 360, height: 70))
            //TaskCell(task: TaskManager.getTestData()[0], editMode: Binding.constant(false)) .previewLayout(.fixed(width: 360, height: 70))
        }
    }
}
#endif
