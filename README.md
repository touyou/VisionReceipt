# VisionReceipt

- [WWDC22 Recap in Goodpatch](https://goodpatch.connpass.com/event/251756/)のLT用に製作したアプリです
- WWDC22で発表されたSwift Regex / Swift ChartsやSwiftUIの新機能を活用して制作したレシート読み取り型簡易家計簿アプリになってます

## Requirements

Xcode 14+
iOS/iPadOS 16+

## Caution

- 試作版です。リポジトリ作者の扱ったレシート以外の形式には対応していない場合があります
- ベータ期間中の動作画面などの共有・ライセンスはAppleのNDA等のルールに従います

## From Presentation

### About

- レシート画像から情報を読み取れる
- それを記録ができる
- 記録がいい感じに見れる

これをとにかく実装を簡単に実装します

### PhotosPicker

```swift
.photosPicker(
    isPresented: $isPresented,
    selection: $pickerItems,
    maxSelectionCount: 1,
    matching: .images,
    preferredItemEncoding: .automatic,
    photoLibrary: PHPhotoLibrary.shared()
)
.onChange(of: pickerItems) { newValue in
    if let value = newValue.first {
        imageLoading = true
        Task {
            try await loadTransferable(from: value)
            await MainActor.run {
                imageLoading = false
            }
        }
    }
}
```

- モディファイアとコンポーネントのふたつの使い方がある
- PhotosPickerは押すと選択用Viewを開くボタンができる
- 裏側はほぼPHPhotoPickerのままだと思われる
- 値はPhotosPickerItemとして返ってくるため変換する必要がある

#### ハマりポイント①

Beta 1のシミュレータでは正常に使えない！

#### ハマりポイント②

```swift
private func loadTransferable(from imageSelection: PhotosPickerItem?) async throws {
    do {
        if let data = try await imageSelection?.loadTransferable(type: Data.self) {
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.uiImage = uiImage
                }
            }
        }
    } catch {
        print("\(#function) | error: \(error)")
    }
}
```

loadTransferableで変換できるのはData型のみ！
Image型もTransferableに適合しているので渡せるが、変換はできない
UIImage型はそもそもTransferableに適合していない

### Visionで日本語認識

```swift
private func executeTextRecognizer() {
    guard let cgImage = uiImage?.cgImage else {
        processLoading = false
        return
    }
    let requestHandler = VNImageRequestHandler(cgImage: cgImage)
    let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
    request.revision = VNRecognizeTextRequestRevision3
    request.recognitionLanguages = ["ja", "en"]
    do {
        try requestHandler.perform([request])
    } catch {
        processLoading = false
        print("Unable to perform the requests: \(error)")
    }
}

private func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        processLoading = false
        return
    }
    let recognizedStringsAndBox = observations.compactMap { observation -> (String, CGPoint)? in
        guard let string = observation.topCandidates(1).first?.string else {
            return nil
        }
        return (string, observation.boundingBox.origin)
    }

    processLoading = false
    let sortedStrings = recognizedStringsAndBox.sorted { lhr, rhr in
        return abs(rhr.1.x - lhr.1.x) <= 0.01 ? lhr.1.y <= rhr.1.y : lhr.1.x <= rhr.1.x
    }
    print("result \(sortedStrings)")

    presentedReceipt = [ReceiptData(contents: sortedStrings.map { $0.0 })]
}
```

- 専用ViewはUIKit向けだけど処理だけならこれでできる
- 処理は残念だながらasync/await未対応のため関数で

#### ハマりポイント①

日本語認識にはRevision指定が必要！
VNRecognizeTextRequestRevision3を指定し
言語にjaを設定しておくこと

#### ハマりポイント②

認識結果は単語ごとの配列、並び順も曖昧
ソートしてあげると確実！
なお、座標は縦がx軸

### Swift Regex

```swift
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
```

- 圧倒的に直感的に書ける
- ちょっとした置換処理も正規表現使わなくてOK
- Captureで一致した結果の一部を個別に取れるように

#### 工夫ポイント①

認識結果の失敗や表記方法のブレを吸収する
「合計」は横長に伸びてると「合言」と認識されるとかを認識結果から観察しておく

#### 工夫ポイント②

文法を調べるのに[岸川さんのサービス](https://swiftregex.com/)を使う！
動作確認にも使えるし、
正規表現の書き方検索して
そこから変換することも

### Swift Charts

```swift
private var entries: [ChartEntry] {
    let sortedDatas = receiptDatas.sorted(by: { $0.date < $1.date })
    let formatter = DateFormatter()
    formatter.dateFormat = "MMdd"
    return sortedDatas.map {
        ChartEntry(date: formatter.string(from: $0.date), value: $0.totalCost())
    }
}
// ...
Chart(entries, id: \.id) { entry in
    BarMark(
        x: .value("日付", entry.date),
        y: .value("値段", entry.value)
    )
    .foregroundStyle(entry.color)
}
.frame(height: 300)
.padding()
// ...
struct ChartEntry: Identifiable {
    let date: String
    let value: Int
    let color: Color = Color(white: .random(in: 0.2...0.8), opacity: 1.0)
    let id: UUID = UUID()
}
```

- SwiftUI®への馴染み度No.1
- 簡単にグラフそれっぽくできちゃう度No.1

#### 工夫ポイント

元の構造体とは別で専用構造体を用意する
色のコントロールとか同じ日付処理とかが
楽になる

### Others

- Xcode®が波括弧閉じたりすると自動フォーマットしてくれるのがすごい便利
- RawRepresentableに適合させると雑にAppStorageに突っ込める
- Sheet内のpush遷移先でdismissするためにDismissActionを受け渡す
- Previewも安定したけど仮データ作るの面倒で今回は使わなかった
- 認識結果にはやはりまだ限界がちょっとあった
