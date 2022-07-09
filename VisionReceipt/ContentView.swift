//
//  ContentView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Yosuke Fujii. All rights reserved.


import SwiftUI
import Charts

struct ContentView: View {
    @AppStorage("receiptDatas") var receiptDatas = ReceiptDatas()
    @State private var showScannerSheet = false
    
    private var entries: [ChartEntry] {
        let sortedDatas = receiptDatas.sorted(by: { $0.date < $1.date })
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        return sortedDatas.map {
            ChartEntry(date: formatter.string(from: $0.date), value: $0.totalCost())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                if receiptDatas.isEmpty {
                    Text("データがありません")
                        .font(.title)
                } else {
                    List {
                        Section("読み取り済みレシート") {
                            ForEach(receiptDatas) { receipt in
                                NavigationLink(destination: List {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text("読み取られた金額")
                                            .font(.body)
                                        Spacer()
                                        Text("¥\(receipt.totalCost())")
                                            .font(.title.bold())
                                    }
                                    .padding()
                                    Text(receipt.entireString)
                                        .textSelection(.enabled)
                                }, label: {
                                    HStack {
                                        Text(receipt.name).lineLimit(1)
                                            .font(.body)
                                        Spacer()
                                        Text(receipt.date, style: .date)
                                            .font(.caption)
                                    }
                                })
                            }
                            .onDelete(perform: {
                                receiptDatas.remove(atOffsets: $0)
                            })
                        }
                        Section("日毎に使った金額") {
                            Chart(entries, id: \.id) { entry in
                                BarMark(
                                    x: .value("日付", entry.date),
                                    y: .value("値段", entry.value)
                                )
                                .foregroundStyle(entry.color)
                            }
                            .frame(height: 300)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Receipt Manager")
            .navigationBarItems(trailing:
                                    Button(action: {
                showScannerSheet = true
            }, label: {
                Image(systemName: "plus.circle")
            })
            )
            .sheet(isPresented: $showScannerSheet, content: {
                ScannerView()
            })
        }
    }
    
    init(showScannerSheet: Bool = false) {
        self.showScannerSheet = showScannerSheet
    }
    
    struct ChartEntry: Identifiable {
        let date: String
        let value: Int
        let color: Color = Color(white: .random(in: 0.2...0.8), opacity: 1.0)
        let id: UUID = UUID()
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#endif
