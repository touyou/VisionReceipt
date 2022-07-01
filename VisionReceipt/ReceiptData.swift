//
//  ReceiptData.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import Foundation

struct ReceiptData: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let contents: [String]

    var entireString: String {
        contents.reduce("", { $0 + "\n" + $1 })
    }

    init(id: UUID = UUID(), name: String = "新しいレシート", contents: [String]) {
        self.id = id
        self.name = name
        self.contents = contents
    }

    func totalCost() -> Int {
        0
    }
}

extension ReceiptData {
    func changeName(_ newName: String) -> ReceiptData {
        ReceiptData(id: id, name: newName, contents: contents)
    }
}


/// ref: https://nilcoalescing.com/blog/SaveCustomCodableTypesInAppStorageOrSceneStorage/
typealias ReceiptDatas = [ReceiptData]

extension ReceiptDatas: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(ReceiptDatas.self, from: data) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}
