//
//  About.swift
//  KHabit
//
//  Created by Stefano Bertoli on 21/09/20.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI


/*
 NB: This is currently not used in the app.
 */


struct InfoRow:View{
    var label:String
    var value:String
    
    var body: some View{
        HStack{
            Text(label).font(.headline)
            Spacer()
            Text(value).font(.body)
        }
    }
}

struct About: View {
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        
        return List{
            InfoRow(label:"App version:", value: "\(appVersion ?? "0.0")")
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("About")
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        TabView{
            About()
        }
    }
}
