//
//  ScannerView.swift
//  VisionReceipt
//
//  Created by Yosuke Fujii on 2022/06/20.
//  Copyright © 2022 Goodpatch. All rights reserved.
    

import SwiftUI
import PhotosUI

struct ScannerView: View {
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var uiImage: UIImage?
    @State private var isPresented: Bool = false
    @State private var loading: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else if loading {
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
                Button(action: {
                    print("proceed vision detect")
                }, label: {
                    Image(systemName: "brain")
                        .font(.title)
                })
                .disabled(uiImage == nil)
            }
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
                loading = true
                Task {
                   try await loadTransferable(from: value)
                    await MainActor.run {
                        loading = false
                    }
                }
            }
        }
        .onAppear {
            PHPhotoLibrary.requestAuthorization({_ in })
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
}

#if DEBUG

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}

#endif
