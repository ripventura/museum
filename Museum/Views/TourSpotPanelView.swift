//
//  TourSpotPanelView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI

struct TourSpotPanelView: View {
    @ObservedObject var tourViewModel: ImmersiveTourViewModel

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                if let spot = tourViewModel.currentSpot {
                    Text(spot.title)
                        .font(.title2)
                        .bold()

                    Text(spot.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 20) {
                    Button("Previous") {
                        tourViewModel.goToPrevious()
                    }
                    .disabled(!tourViewModel.canGoPrevious)

                    Spacer()

                    Button("Next") {
                        tourViewModel.goToNext()
                    }
                    .disabled(!tourViewModel.canGoNext)
                }
            }
            .padding(24)
            .frame(width: 380)
            .glassBackgroundEffect()
        }
    }
}
