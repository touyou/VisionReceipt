//
//  CheckView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/07/01.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import SwiftUI

struct CheckView: View {
    @AppStorage("receiptDatas") var receiptDatas = ReceiptDatas()
    @State private var isShowingAlert: Bool = false
    @State private var name: String = "新しいレシート"
    @State var receiptData: ReceiptData
    var dismiss: DismissAction

    var body: some View {
        Form {
            TextField("レシート名", text: $name)
            Text(receiptData.entireString)
        }
        .navigationBarTitle(Text("認識結果"))
        .navigationBarItems(trailing:
            Button("保存") {
                receiptDatas.append(receiptData.changeName(name))
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