//
//  ContentView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import SwiftUI

struct ContentView: View {
    @State private var showScannerSheet = false
    @State private var receipts: [ReceiptData] = []

    init(showScannerSheet: Bool = false, receipts: [ReceiptData] = []) {
        self.showScannerSheet = showScannerSheet
        self.receipts = receipts
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                if receipts.isEmpty {
                    Text("データがありません")
                        .font(.title)
                } else {
                    List {
                        ForEach(receipts) { receipt in
                            NavigationLink(destination:
                                ScrollView {
                                    Text(receipt.content)
                                }, label: {
                                    Text(receipt.content).lineLimit(1)
                                })
                        }
                    }
                }
            }
                .navigationTitle("Receipt Manager")
                .navigationBarItems(trailing: Button(action: {
                    showScannerSheet = true
                }, label: {
                    Image(systemName: "plus.circle")
                        .font(.title)
                }))
                .sheet(isPresented: $showScannerSheet, content: {
                    ScannerView()
                })
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(receipts: [
            ReceiptData(content: "Hello"),
            ReceiptData(content: "World")
        ])
    }
}

#endif
