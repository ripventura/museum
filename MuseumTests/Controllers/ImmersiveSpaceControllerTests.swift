//
//  ImmersiveSpaceControllerTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 26/02/19.
//

import Testing
@testable import Museum

@MainActor
struct ImmersiveSpaceControllerTests {

    @Test("Initial phase is closed")
    func initialPhaseIsClosed() {
        let sut = makeSUT()

        #expect(sut.phase == .closed)
    }

    @Test("Phase can be set to opening")
    func phaseCanBeSetToOpening() {
        let sut = makeSUT()

        sut.phase = .opening

        #expect(sut.phase == .opening)
    }

    @Test("Phase can be set to open")
    func phaseCanBeSetToOpen() {
        let sut = makeSUT()

        sut.phase = .open

        #expect(sut.phase == .open)
    }

    @Test("Phase can be set to error")
    func phaseCanBeSetToError() {
        let sut = makeSUT()

        sut.phase = .error

        #expect(sut.phase == .error)
    }

    @Test("Phase transitions from open back to closed")
    func phaseTransitionsFromOpenToClosed() {
        let sut = makeSUT()

        sut.phase = .open
        sut.phase = .closed

        #expect(sut.phase == .closed)
    }
}

// MARK: - Private

@MainActor
private extension ImmersiveSpaceControllerTests {
    func makeSUT() -> ImmersiveSpaceController {
        ImmersiveSpaceController()
    }
}
