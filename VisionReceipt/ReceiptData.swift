//
//  ReceiptData.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/19.
//  Copyright © 2022 Yosuke Fujii. All rights reserved.
    

import Foundation
import RegexBuilder

struct ReceiptData: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let contents: [String]

    var entireString: String {
        contents.reduce("", { $0 + "\n" + $1 })
    }

    init(id: UUID = UUID(), name: String = "新しいレシート", date: Date = Date(), contents: [String]) {
        self.id = id
        self.name = name
        self.date = date
        self.contents = contents
    }
}

extension ReceiptData {
    func changedName(_ newName: String) -> ReceiptData {
        ReceiptData(id: id, name: newName, date: date, contents: contents)
    }

    func changedDate(_ newDate: Date) -> ReceiptData {
        ReceiptData(id: id, name: name, date: newDate, contents: contents)
    }

    func changed(name newName: String, date newDate: Date) -> ReceiptData {
        ReceiptData(id: id, name: newName, date: newDate, contents: contents)
    }
}

extension ReceiptData {
    func totalCost() -> Int {
        let pattern = Regex {
            ChoiceOf {
                "合言"
                "合計"
                "クレジット"
            }
            ZeroOrMore(.whitespace.inverted)
            ZeroOrMore(.whitespace)
            "¥"
            Capture {
                Regex {
                    ZeroOrMore(.digit)
                    Optionally(",")
                    OneOrMore(.digit)
                }
            }
        }
        if let match = entireString.firstMatch(of: pattern) {
            let  (_, costString) = match.output
            return Int(String(costString.replacing(Regex { "," }, with: { _ in "" }))) ?? -1
        }
        return -1
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
