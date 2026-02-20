//
//  ImmersiveTourViewModelTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 26/02/19.
//

import simd
import Testing
@testable import Museum

@MainActor
struct ImmersiveTourViewModelTests {

    // MARK: - Initial State

    @Test("currentSpotIndex starts at 0")
    func currentSpotIndexStartsAtZero() {
        let sut = makeSUT()

        #expect(sut.currentSpotIndex == 0)
    }

    @Test("currentSpot returns first tour spot initially")
    func currentSpotIsFirstSpotInitially() {
        let sut = makeSUT()

        #expect(sut.currentSpot == Asset.warship.tourSpots[0])
    }

    @Test("canGoPrevious is false at first spot")
    func canGoPreviousIsFalseAtStart() {
        let sut = makeSUT()

        #expect(sut.canGoPrevious == false)
    }

    @Test("canGoNext is true when multiple spots exist")
    func canGoNextIsTrueWithMultipleSpots() {
        let sut = makeSUT()

        #expect(sut.canGoNext == true)
    }

    // MARK: - goToNext

    @Test("goToNext increments index")
    func goToNextIncrementsIndex() {
        let sut = makeSUT()

        sut.goToNext()

        #expect(sut.currentSpotIndex == 1)
        #expect(sut.currentSpot == Asset.warship.tourSpots[1])
    }

    @Test("goToNext at last spot wraps to first spot")
    func goToNextAtLastSpotWrapsToFirst() {
        let sut = makeSUT()
        let lastIndex = Asset.warship.tourSpots.count - 1

        for _ in 0..<lastIndex { sut.goToNext() }
        #expect(sut.currentSpotIndex == lastIndex)

        sut.goToNext()

        #expect(sut.currentSpotIndex == 0)
        #expect(sut.currentSpot == Asset.warship.tourSpots[0])
    }

    // MARK: - goToPrevious

    @Test("goToPrevious decrements index")
    func goToPreviousDecrementsIndex() {
        let sut = makeSUT()
        sut.goToNext()

        sut.goToPrevious()

        #expect(sut.currentSpotIndex == 0)
        #expect(sut.currentSpot == Asset.warship.tourSpots[0])
    }

    @Test("goToPrevious at first spot does not decrement index")
    func goToPreviousAtFirstSpotIsNoOp() {
        let sut = makeSUT()

        sut.goToPrevious()

        #expect(sut.currentSpotIndex == 0)
    }

    // MARK: - Boundaries

    @Test("canGoNext remains true at last spot")
    func canGoNextIsTrueAtLastSpot() {
        let sut = makeSUT()
        let lastIndex = Asset.warship.tourSpots.count - 1

        for _ in 0..<lastIndex { sut.goToNext() }

        #expect(sut.canGoNext == true)
    }

    @Test("canGoPrevious becomes true after goToNext")
    func canGoPreviousIsTrueAfterGoToNext() {
        let sut = makeSUT()

        sut.goToNext()

        #expect(sut.canGoPrevious == true)
    }

    @Test("canGoPrevious is false after wrapping to first spot")
    func canGoPreviousIsFalseAfterWrap() {
        let sut = makeSUT()
        let spotCount = Asset.warship.tourSpots.count

        for _ in 0..<spotCount { sut.goToNext() }

        #expect(sut.currentSpotIndex == 0)
        #expect(sut.canGoPrevious == false)
    }

    // MARK: - entityOrientation

    @Test("entityOrientation returns identity for zero euler angles")
    func entityOrientationIdentityForZeroEuler() {
        let sut = makeSUT()
        let spot = Asset.TourSpot(
            title: "",
            description: "",
            entityPosition: .zero,
            entityOrientation: SIMD3<Float>(0, 0, 0)
        )

        let result = sut.entityOrientation(for: spot)

        #expect(abs(result.real - 1) < 1e-5)
        #expect(abs(result.imag.x) < 1e-5)
        #expect(abs(result.imag.y) < 1e-5)
        #expect(abs(result.imag.z) < 1e-5)
    }

    @Test("entityOrientation applies Y rotation for pi/2 around Y axis")
    func entityOrientationYRotation() {
        let sut = makeSUT()
        let spot = Asset.TourSpot(
            title: "",
            description: "",
            entityPosition: .zero,
            entityOrientation: SIMD3<Float>(0, .pi / 2, 0)
        )

        let result = sut.entityOrientation(for: spot)
        let expected = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))

        #expect(abs(result.real - expected.real) < 1e-5)
        #expect(abs(result.imag.x - expected.imag.x) < 1e-5)
        #expect(abs(result.imag.y - expected.imag.y) < 1e-5)
        #expect(abs(result.imag.z - expected.imag.z) < 1e-5)
    }

    @Test("entityOrientation composes rotations in Y*X*Z order")
    func entityOrientationComposesYXZ() {
        let sut = makeSUT()
        let spot = Asset.TourSpot(
            title: "",
            description: "",
            entityPosition: .zero,
            entityOrientation: SIMD3<Float>(.pi / 4, .pi / 3, .pi / 6)
        )

        let result = sut.entityOrientation(for: spot)

        let qx = simd_quatf(angle: .pi / 4, axis: SIMD3<Float>(1, 0, 0))
        let qy = simd_quatf(angle: .pi / 3, axis: SIMD3<Float>(0, 1, 0))
        let qz = simd_quatf(angle: .pi / 6, axis: SIMD3<Float>(0, 0, 1))
        let expected = qy * qx * qz

        #expect(abs(result.real - expected.real) < 1e-5)
        #expect(abs(result.imag.x - expected.imag.x) < 1e-5)
        #expect(abs(result.imag.y - expected.imag.y) < 1e-5)
        #expect(abs(result.imag.z - expected.imag.z) < 1e-5)
    }

    // MARK: - configure

    @Test("configure resets index to 0")
    func configureResetsIndex() {
        let sut = makeSUT()
        sut.goToNext()
        #expect(sut.currentSpotIndex == 1)

        sut.configure(for: .warship)

        #expect(sut.currentSpotIndex == 0)
    }
}

// MARK: - Private

@MainActor
private extension ImmersiveTourViewModelTests {
    func makeSUT() -> ImmersiveTourViewModel {
        let sut = ImmersiveTourViewModel()
        sut.configure(for: .warship)
        return sut
    }
}
