//
//  StatsView.swift
//  KHabit
//
//  Created by Stefano Bertoli on 24/09/20.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI

//Structure to handle day completions
struct DayCompletions:Identifiable{
    var id:Int
    var date:Date
    var completions:[CDTaskCompletion]
    
    func dateStr(format: String)->String{
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: self.date)
    }
}


///Utility customized detail text view
struct DetailText:View {
    var text:String
    
    var body: some View{
        Text(self.text)
            .font(.custom("graphLabel", size: 10))
            .lineLimit(nil)
            .fixedSize()
            .frame(width:1)
            .rotationEffect(.degrees(-60))
            .offset(x: -8, y: 16)
    }
}



///Retrieve all the completions for the last N days
func getCompletionsForLast(nDays n:Int )->[DayCompletions]{
    var data:[DayCompletions] = []
    for i in 0...n-1{
        let day = Date().addingTimeInterval(TimeInterval(-1 * i * 24 * 60 * 60))
        let completions = TaskManager.shared.tasksCompleted(atDate: day)
        data.append(DayCompletions(id:i, date: day, completions: completions))
    }
    return data.reversed()
}


///Get the max value of completions in a day from a DayCompletions array
func dayCompletionsMax(data:[DayCompletions]) -> Int{
    return data.reduce(0) { (curr, item) -> Int in return max(curr, item.completions.count) }
}


///Graph view for the last 30 days
struct graph_30days: View{
    //States
    @Binding var data:[DayCompletions]
    @State var animations:[Bool] = Array(repeating: false, count: 31)

    //Constants
    @Environment(\.colorScheme) var cs
    let graphHeight:CGFloat = 60

    ///Animation utility function to delay the animation for each bar
    func toggleAfterDelay(delay:Int){
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(30-delay)*0.025, execute: {
            withAnimation(Animation.easeInOut(duration: 1)){self.animations[delay].toggle()}
        })
    }
    
    
    var body: some View{
        //Get the max completions value
        let m:CGFloat = max(CGFloat(data.reduce(0) { (curr, i) -> Int in return max(curr, i.completions.count) }), 1)

        //Actual body
        return HStack{
            //For each day
            ForEach(data){ d in
                //Column
                VStack{
                    //Aligned on bottom
                    Spacer()
                    
                    //Graph bar
                    RoundedRectangle(cornerRadius: 4)
                        .frame(height: self.animations[d.id] ? max(CGFloat(d.completions.count)/m * graphHeight, 1) : 1)
                        .foregroundColor(dayCompletionsMax(data: self.data) == d.completions.count ? (cs == .dark ? accDark : accLight) : (cs == .dark ? .white : .black))
                        .onAppear(perform:{ if !self.animations[d.id] {self.toggleAfterDelay(delay: d.id)}})

                    //Date text (visible only one every 3)
                    DetailText(text: d.dateStr(format: "MMM dd"))
                        .opacity(d.id % 3 == 0 ? 1 : 0)
                }
                .frame(height: graphHeight+32)
                .padding(-3)
            }
        }
        .onDisappear(perform: {
            for i in 0...self.animations.count-1{
                if self.animations[i]{ self.animations[i].toggle() }
            }
        })
    }
}


///Graph view for the weekday
struct graph_weekday: View{
    //States
    @Binding var weekdayStats: [Day:Int]
    @State var animations: [Bool] = Array(repeating: false, count: 7)
    
    //Constants
    @Environment(\.colorScheme) var cs
    let weekdays:[Day] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
    let graphHeight:CGFloat = 60

    ///Animation utility function to delay the animation for each bar
    func toggleAfterDelay(delay:Int){
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(7-delay)*0.025, execute: {
            withAnimation(Animation.easeInOut(duration: 1)) { self.animations[delay].toggle() }
        })
    }

    
    var body: some View{
        HStack{
            //Foreach day
            ForEach(values: 0...6){ i in
                //Column
                VStack{
                    //Aligned bottom
                    Spacer()
                    
                    //Counter
                    Text("\(self.weekdayStats[weekdays[i]]!)").font(.footnote)
                        .bold()
                        .opacity(self.weekdayStats[weekdays[i]]! > 0 ? 1 : 0)

                    //Rectangle
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(self.weekdayStats[weekdays[i]]! == self.weekdayStats.values.max()! ? (cs == .dark ? accDark : accLight) : (cs == .dark ? .white : .black))
                        .frame(height: self.animations[i] ? max(1, CGFloat(weekdayStats[weekdays[i]]!) / CGFloat(weekdayStats.values.max()!) * graphHeight) : 1)
                        .onAppear(perform:{ if !self.animations[i] { self.toggleAfterDelay(delay: i) }})
                    
                    //Name of the day
                    DetailText(text: weekdays[i].rawValue)
                }
                .frame(height: graphHeight+64)
            }
        }
        .onDisappear(perform: {
            for i in 0...self.animations.count-1{
                if self.animations[i]{ self.animations[i].toggle() }
            }
        })
    }
}


///View for task completion graph
struct graph_taskCompletions:View{
    //States
    @Binding var taskCompletionsStats:[TaskCompletionStat]
    @Environment(\.colorScheme) var cs
    
    var body: some View{
        VStack{
            //For each task
            ForEach(self.taskCompletionsStats, id:\.task.id){d in
                //Row
                HStack(){
                    //Counter
                    Text("\(d.count)").bold()
                        .font(.title3)
                        .frame(maxWidth:45)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(cs == .dark ? accDark : accLight, lineWidth: 2)
                                .opacity(d.task.id == self.taskCompletionsStats.first!.task.id ? 1 : 0)
                        )
                        .padding(.leading, 24)
                    
                    //Name
                    Text(d.task.name ?? "")
                        .font(.body)
                    
                    //Aligned left
                    Spacer()
                }
            }
        }
    }
}



///Main statistics view
struct StatsView: View {
    //States
    @State var weekdayStats: [Day:Int] = TaskManager.shared.getWeekdayStats()
    @State var taskCompletionsStats:[TaskCompletionStat] = TaskManager.shared.getTaskCompletionsStats()
    @State var data:[DayCompletions] = getCompletionsForLast(nDays: 31)

    //Constants
    @Environment(\.colorScheme) var cs
    let sectionSepH:CGFloat = 64
    
    @ViewBuilder
    var body: some View {
        ScrollView{
            LazyVStack{
                //Last 30 days graph
                Text("Last 30 days").font(.title).bold()
                    .frame(maxWidth:.infinity, alignment:.leading)
                    .padding(.top, sectionSepH/2)
                    .padding(.leading , 24)
                graph_30days(data: self.$data)
                    .padding(.horizontal, 32)
                
                
                //Weekday graph
                Text("Weekday stats").font(.title).bold()
                    .frame(maxWidth:.infinity, alignment:.leading)
                    .padding(.top, sectionSepH)
                    .padding(.leading , 24)
                graph_weekday(weekdayStats: self.$weekdayStats)
                    .padding(.horizontal, 32)
                
                
                //Task completions graph
                Text("Task completions").font(.title).bold()
                    .frame(maxWidth:.infinity, alignment:.leading)
                    .padding(.top , sectionSepH)
                    .padding(.leading , 24)
                graph_taskCompletions(taskCompletionsStats: self.$taskCompletionsStats)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
        }
        .onAppear(perform: {
            print("Reloading stat data")
            data = getCompletionsForLast(nDays: 31)
            weekdayStats = TaskManager.shared.getWeekdayStats()
            taskCompletionsStats = TaskManager.shared.getTaskCompletionsStats()
        })
        .navigationTitle("Statistics")
    }
}


#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        TabView{
            NavigationView{
                Text("ciao")
            }
            .tabItem { Text("ciro") }
            .tag(0)
            NavigationView{
                StatsView()
            }
            .tabItem { Text("ciro") }
            .tag(1)
        }.colorScheme(.dark)
    }
}
#endif
