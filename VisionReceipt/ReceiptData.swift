//
//  ReceiptData.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import Foundation

struct ReceiptData: Identifiable {
    let id = UUID()
    var content: String

    init(content: String) {
        self.content = content
    }
}

