//
//  ImmersiveSpaceController.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import Combine
import FactoryKit

// MARK: - DI Registration

extension Container {
    @MainActor
    var immersiveSpaceController: Factory<ImmersiveSpaceController> {
        self { @MainActor in ImmersiveSpaceController() }
            .singleton
    }
}

// MARK: - Protocol

protocol ImmersiveSpaceControlling: ObservableObject {
    var phase: ImmersiveSpacePhase { get set }
}

// MARK: - Implementation

final class ImmersiveSpaceController: ImmersiveSpaceControlling, ObservableObject {
    @Published var phase: ImmersiveSpacePhase = .closed
}
