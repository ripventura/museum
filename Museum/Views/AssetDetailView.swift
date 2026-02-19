//
//  AssetDetailView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI
import RealityKit

struct AssetDetailView: View {
    let url: URL

    var body: some View {
        Model3D(url: url) { model in
            model
                .resizable()
                .scaledToFit()
        } placeholder: {
            VStack {
                ProgressView()
                Text("Loading experience...")
            }
            .font(.headline)
        }
    }
}
