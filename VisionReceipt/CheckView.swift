//
//  CheckView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/07/01.
//  Copyright © 2022 Yosuke Fujii. All rights reserved.
    

import SwiftUI

struct CheckView: View {
    @AppStorage("receiptDatas") var receiptDatas = ReceiptDatas()
    @State private var isShowingAlert: Bool = false
    @State private var name: String = "新しいレシート"
    @State private var date: Date = Date()
    @State var receiptData: ReceiptData
    var dismiss: DismissAction

    var body: some View {
        Form {
            TextField("レシートの名前", text: $name)
            DatePicker("日付", selection: $date, displayedComponents: [.date])
            Text("読み取られた金額 ¥\(receiptData.totalCost())")
            Text(receiptData.entireString)
        }
        .navigationBarTitle(Text("認識結果"))
        .navigationBarItems(trailing:
            Button("保存") {
                receiptDatas.append(receiptData.changed(name: name, date: date))
                isShowingAlert = true
            }
        )
        .interactiveDismissDisabled(true)
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("保存しました"), dismissButton: .default(Text("OK"), action: {
                dismiss()
            }))
        }
    }
}
