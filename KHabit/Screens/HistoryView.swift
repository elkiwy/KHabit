//
//  StatsView.swift
//  KHabit
//
//  Created by Stefano Bertoli on 27/06/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI

///Get all the completions for every task
func getCompletions() -> [CDTaskCompletion] {
    return TaskManager.shared.tasks.flatMap { (task) -> [CDTaskCompletion] in return task.history?.allObjects as! [CDTaskCompletion] }
}


///Single cell for completions in day completions list
struct CompletionCell:View {
    @State var completion:CDTaskCompletion
    @State var description:String = ""
    
    var body: some View{
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        
        return HStack{
            VStack(alignment: .leading){
                Text("\(self.completion.task!.name!)").font(.headline)
                Text(self.description).font(.subheadline)
            }
            Spacer()
            VStack{
                Spacer()
                Text(df.string(from: self.completion.date!)).font(.footnote)
            }
        }.onAppear(perform: {
            self.description = self.completion.note ?? ""
        })
    }
}


///Handy date to string
func dateStr(_ date:Date)->String{
    let df = DateFormatter()
    df.dateFormat = "dd MMM yyyy"
    return df.string(from: date)
}


///Main view
struct HistoryView: View {
    //States
    @State var selectedDate:Date = Date()
    @State var completions:[CDTaskCompletion] = TaskManager.shared.tasksCompleted(atDate: Date())

    var body: some View {
        //Extra bind to listen to selectedDate changes and update completions on changes
        let dateBind = Binding<Date> {
            return self.selectedDate
        } set: {
            self.selectedDate = $0
            self.completions = TaskManager.shared.tasksCompleted(atDate: self.selectedDate)
        }

        //Actual body
        return ScrollView{
            VStack{
                //Calendar
                CalendarView(date: Date(), selectedDate: dateBind)

                //Note Title
                HStack{Text("Completion for \(dateStr(self.selectedDate))").font(.title3).bold(); Spacer()}
                    .padding(.vertical)
                
                //Notes
                ForEach(self.completions) { c in
                    CompletionCell(completion: c)
                }
            }
        }
        .listStyle(PlainListStyle())
        
        //View title
        .navigationBarTitle("History")
        
        //Extras
        .onAppear(perform: {
            self.completions = TaskManager.shared.tasksCompleted(atDate: self.selectedDate)
        })
        .padding(.horizontal)
    }
}


#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().colorScheme(.dark)
    }
}
#endif
