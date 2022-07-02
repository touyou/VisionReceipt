//
//  ScannerView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/20.
//  Copyright © 2022 Yosuke Fujii. All rights reserved.
    

import SwiftUI
import PhotosUI
import Vision

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var uiImage: UIImage?
    @State private var isPresented: Bool = false
    @State private var imageLoading: Bool = false
    @State private var processLoading: Bool = false
    @State private var presentedReceipt: [ReceiptData] = []

    var body: some View {
        NavigationStack(path: $presentedReceipt) {
            VStack(spacing: 24) {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else if imageLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Rectangle()
                        .fill(.gray)
                        .frame(maxHeight: 300)
                }
                HStack(alignment: .center, spacing: 16) {
                    Button(action: {
                        isPresented = true
                    }, label: {
                        Image(systemName: "photo.fill")
                            .font(.title)
                    })
                    .disabled(processLoading)
                    Button(action: {
                        processLoading = true
                        executeTextRecognizer()
                    }, label: {
                        if processLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "brain")
                                .font(.title)
                        }
                    })
                    .disabled(uiImage == nil)
                }
            }
            .navigationDestination(for: ReceiptData.self) { receipt in
                CheckView(receiptData: receipt, dismiss: dismiss)
            }
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
            .onAppear {
                PHPhotoLibrary.requestAuthorization({_ in })
            }
        }
    }

    // NOTE: DataじゃないとloadTransferableが正常に機能しない
    // ref: https://github.com/StewartLynch/PhotosPicker/blob/main/PhotosPicker/ImageModel.swift
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

    /// 文字認識を走らせる
    /// ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images/
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
}

#if DEBUG

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}

#endif
