//
//  ContentView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import SwiftUI

struct ContentView: View {
    @AppStorage("receiptDatas") var receiptDatas = ReceiptDatas()
    @State private var showScannerSheet = false

    init(showScannerSheet: Bool = false) {
        self.showScannerSheet = showScannerSheet
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                if receiptDatas.isEmpty {
                    Text("データがありません")
                        .font(.title)
                } else {
                    List {
                        ForEach(receiptDatas) { receipt in
                            NavigationLink(destination:
                                ScrollView {
                                    Text(receipt.entireString)
                                        .padding()
                                }, label: {
                                    Text(receipt.name).lineLimit(1)
                                })
                        }
                        .onDelete(perform: {
                            receiptDatas.remove(atOffsets: $0)
                        })
                    }
                }
            }
                .navigationTitle("Receipt Manager")
                .navigationBarItems(trailing: HStack {
                    Button(action: {
                        print("グラフを表示する")
                    }, label: {
                        Image(systemName: "chart.bar.xaxis")
                    })
                    Button(action: {
                        showScannerSheet = true
                    }, label: {
                        Image(systemName: "plus.circle")
                    })
                })
                .sheet(isPresented: $showScannerSheet, content: {
                    ScannerView()
                })
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#endif
