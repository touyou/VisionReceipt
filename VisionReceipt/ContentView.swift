//
//  ContentView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
