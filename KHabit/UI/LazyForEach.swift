//
//  LazyForEach.swift
//  KHabit
//
//  Created by Stefano Bertoli on 09/07/2020.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI




struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
