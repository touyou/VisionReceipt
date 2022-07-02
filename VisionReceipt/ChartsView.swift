//
//  ChartsView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/07/02.
//  Copyright © 2022 Yosuke Fujii. All rights reserved.
    

import SwiftUI
import Charts

struct ChartsView: View {
    @AppStorage("receiptDatas") var receiptDatas = ReceiptDatas()

    private var entries: [ChartEntry] {
        let sortedDatas = receiptDatas.sorted(by: { $0.date < $1.date })
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return sortedDatas.map { ChartEntry(date: formatter.string(from: $0.date), value: $0.totalCost()) }

    }

    var body: some View {
        VStack {
            Text("使った金額グラフ")
                .font(.title.bold())
            Chart(entries, id: \.id) { entry in
                LineMark(
                    x: .value("日付", entry.date),
                    y: .value("値段", entry.value)
                )
                PointMark(
                    x: .value("日付", entry.date),
                    y: .value("値段", entry.value)
                )
            }
            .padding()
        }
    }

    struct ChartEntry: Identifiable {
        let date: String
        let value: Int
        let id: UUID = UUID()
    }
}

struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView()
    }
}
