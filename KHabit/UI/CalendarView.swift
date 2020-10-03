//
//  CalendarView.swift
//  KHabit
//
//  Created by Stefano Bertoli on 29/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI


struct Arc: Shape {
    var startAngle: Double
    var endAngle: Double
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: clockwise)
        return path
    }
    
    var animatableData: AnimatablePair<Double, Double> {
        get { return AnimatablePair(startAngle, endAngle) }
        set { startAngle = newValue.first; endAngle = newValue.second }
    }
}



struct CalendarHeader: View{
    var name: String
    var body: some View{
        Text(self.name)
            .frame(maxWidth: .infinity, maxHeight: 32)
            .font(.headline)
    }
}



struct CalendarCell: View{
    //Logic
    @State var completions:Int = 0
    @Binding var selectedDate:Date
    var date: Date
    var month:Int

    //Theme
    @Environment(\.colorScheme) var colorScheme
    
    //Animation stuff
    @State var animValue: Double = 0.0
    @State var startAngle: Double = 0
    var animation = Animation.easeInOut(duration: 1)

    
    ///Init
    init(date:Date, selectedDate:Binding<Date>, month:Int) {
        _selectedDate = selectedDate
        self.date = date
        self.month = month
    }
    
    ///Body
    var body: some View{
        //Listen for updates on selectedDate and updates the animation
        let _ = Binding<Bool>(get: { () -> Bool in
            let selected = Calendar.current.isDate(self.selectedDate, inSameDayAs: self.date)
            DispatchQueue.main.async {
                withAnimation(animation){
                    self.animValue = selected ? 360 : 0
                    self.startAngle = selected ? 180 : 0
                }
                self.completions = TaskManager.shared.tasksCompleted(atDate: date).count
            }
            return selected
        }) { (sel) in }
                
        //Check if i'm in the correct month or i'm an outsider
        let dateInCurrentMonth = Calendar.current.component(.month, from: self.date) == self.month
                
        //Actual body
        return Button(action: {
            self.selectedDate = self.date
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack{
                Text("\(Calendar.current.component(.day, from: self.date))").font(.headline)
                Text("\(self.completions)").font(.caption)
                    .opacity(self.completions > 0 ? 1 : 0)
            }
            .opacity(dateInCurrentMonth ? 1 : 0.25)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .overlay(
            Arc(startAngle: self.startAngle, endAngle: self.startAngle + self.animValue, clockwise: false)
                .stroke(self.colorScheme == .dark ? accDark : accLight, lineWidth: 2)
        )
        .onAppear(perform: {
            self.completions = TaskManager.shared.tasksCompleted(atDate: self.date).count
        })

    }
}




let h24:TimeInterval = 24*60*60
let d7:TimeInterval = h24*7
struct CalendarView: View {
    @State var date:Date
    @State private var firstOfTheMonth:Date!
    @State private var startingDate:Date!
    @State private var monthName:String!
    @Binding var selectedDate:Date

    init(date:Date, selectedDate:Binding<Date>) {
        _selectedDate = selectedDate
        _date = State(initialValue: date)
        let comps = Calendar.current.dateComponents([.month, .year], from: self.date)
        _firstOfTheMonth = State(initialValue: Calendar.current.date(from: comps))
        let weekday = Calendar.current.component(.weekday, from: self.firstOfTheMonth)
        let offset:TimeInterval = Double(weekday - 2) * h24 * -1
        _startingDate = State(initialValue: self.firstOfTheMonth.addingTimeInterval(offset))
        let df = DateFormatter(); df.dateFormat = "LLLL"
        _monthName = State(initialValue: df.string(from: self.date))
    }
    
    func update(){
        let comps = Calendar.current.dateComponents([.month, .year], from: self.date)
        self.firstOfTheMonth = Calendar.current.date(from: comps)
        let weekday = Calendar.current.component(.weekday, from: self.firstOfTheMonth)
        let offset:TimeInterval = Double(weekday - 2) * h24 * -1
        self.startingDate = self.firstOfTheMonth.addingTimeInterval(offset)
        let df = DateFormatter()
        df.dateFormat = "LLLL"
        self.monthName = df.string(from: self.date)
    }
    

    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    self.date = Calendar.current.date(byAdding: .month, value: -1, to: self.date)!
                    self.update()
                }) { IconArrow(name: "chevron.left", size: 32) }
                Spacer()
                Text(monthName + " " + String(Calendar.current.component(.year, from: self.date))).font(.title)
                Spacer()
                Button(action: {
                    self.date = Calendar.current.date(byAdding: .month, value: 1, to: self.date)!
                    self.update()
                }) { IconArrow(name: "chevron.right", size: 32) }
            }
            .padding()
            HStack(spacing:0){
                CalendarHeader(name:"Mon")
                CalendarHeader(name:"Tue")
                CalendarHeader(name:"Wed")
                CalendarHeader(name:"Thu")
                CalendarHeader(name:"Fri")
                CalendarHeader(name:"Sat")
                CalendarHeader(name:"Sun")
            }
            ForEach(values: [0,1,2,3,4]){ i in
                HStack(spacing:0){
                    ForEach(values: [0,1,2,3,4,5,6]){j in
                        CalendarCell(date: self.startingDate.addingTimeInterval(d7*Double(i) + h24 * Double(j)),
                                     selectedDate: self.$selectedDate,
                                     month: Calendar.current.component(.month, from: self.date))
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .global)
                .onChanged({ (v) in
                    print(v.translation.width)
                })
                .onEnded({ (v) in
                    if (v.translation.width > 0){
                        self.date = Calendar.current.date(byAdding: .month, value: -1, to: self.date)!
                    }else{
                        self.date = Calendar.current.date(byAdding: .month, value:  1, to: self.date)!
                    }
                    self.update()
                })
        )
    }
}




#if DEBUG
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        //CalendarView(date: Date().addingTimeInterval(-10*24*60*60), selectedDate: Binding.constant(Date()))
            //.background(Color.red)
        
        HistoryView().colorScheme(.dark)
    }
}
#endif
