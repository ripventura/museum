//
//  AssetLoadingView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI
import Equatable

@Equatable
struct AssetLoadingView: View {
    let progress: Float

    var body: some View {
        VStack(spacing: 40) {
            Text("Downloading Asset")
                .font(.title)

            VStack(spacing: 10) {
                ProgressView(value: Double(progress))
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                Text("\(Int(progress * 100))%")
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 300)
        .glassBackgroundEffect()
    }
}
