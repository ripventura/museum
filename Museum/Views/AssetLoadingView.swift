//
//  AssetLoadingView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI

struct AssetLoadingView: View {
    let progress: Float

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(progress))
                .progressViewStyle(.linear)
                .frame(width: 200)
            Text("Downloading asset… \(Int(progress * 100))%")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
