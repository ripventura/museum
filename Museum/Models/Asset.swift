//
//  Asset.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import simd

nonisolated enum Asset: String, CaseIterable, Sendable, CacheKeyProtocol {
    case warship = "KM1PUvbAai5kXm8"

    var value: String { rawValue }
    var fileExtension: String? { "usdz" }

    var title: String {
        switch self {
        case .warship: "USS Gato (SS-212)"
        }
    }

    var offsetZ: Float? {
        switch self {
        case .warship: 400
        }
    }

    var tourSpots: [TourSpot] {
        switch self {
        case .warship: [
            TourSpot(
                title: "Overview",
                description: "USS Gato (hull number SS-212) was the lead ship of her class of submarine in the United States Navy. She was the first Navy ship named for the common name used for a number of species of catshark. She was commissioned only days after the declaration of war and made thirteen combat patrols during World War II. She survived the war and spent the post-war period as a training ship before being sold for scrapping in 1960.",
                entityPosition: SIMD3<Float>(-10, -5, -15),
                entityOrientation: SIMD3<Float>(0, .pi / 2, 0)
            ),
            TourSpot(
                title: "Forward Torpedo Room",
                description: "Six 21-inch torpedo tubes armed the bow of USS Gato. With 24 torpedoes stored aboard, the crew could sustain prolonged combat patrols across the Pacific. During her fourth war patrol in early 1943, Gato sank three Japanese vessels off the Solomon Islands from this very firing position.",
                entityPosition: SIMD3<Float>(-35, -3, -30),
                entityOrientation: SIMD3<Float>(0, .pi / 3, 0)
            ),
            TourSpot(
                title: "Conning Tower & Bridge",
                description: "The conning tower housed the periscopes, bridge, and observation deck from which officers directed attacks while submerged. Two periscopes of considerable length allowed the crew to scan the horizon for targets and threats. The tower grew in size throughout the war as more weapons and sensors were added.",
                entityPosition: SIMD3<Float>(-10, -8, -10),
                entityOrientation: SIMD3<Float>(0, .pi / 2, 0)
            ),
            TourSpot(
                title: "Deck Gun Platform",
                description: "A 4-inch/50-caliber deck gun was mounted aft of the sail for surface engagements. Used against targets within minimum torpedo range or to finish off damaged vessels, it was complemented by a 40mm Bofors and a 20mm Oerlikon cannon for anti-aircraft defense. Gunnery platforms were fitted both fore and aft of the conning tower.",
                entityPosition: SIMD3<Float>(-2, -10, -6),
                entityOrientation: SIMD3<Float>(0, .pi / 1.2, 0)
            ),
            TourSpot(
                title: "Stern Torpedo Room",
                description: "Four additional 21-inch torpedo tubes at the stern allowed Gato to attack while withdrawing. This rear armament proved vital in wolf pack tactics — during her eleventh patrol in the Yellow Sea, Gato coordinated with submarines Jallao and Sunfish to hunt Japanese shipping, sinking a coast defense ship and the cargo vessel Tairiku Maru in February 1945.",
                entityPosition: SIMD3<Float>(10, -3, -54),
                entityOrientation: SIMD3<Float>(0, .pi / 1.1, 0)
            ),
        ]
        }
    }

    nonisolated struct TourSpot: Sendable, Equatable {
        let title: String
        let description: String
        let entityPosition: SIMD3<Float>
        let entityOrientation: SIMD3<Float>
    }
}
