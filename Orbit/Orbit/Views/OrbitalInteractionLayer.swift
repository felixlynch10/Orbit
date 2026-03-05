import SwiftUI

/// Transparent interaction layer over the orbital view.
/// Handles hover (continuous) and tap gestures, updating store state.
struct OrbitalInteractionLayer: View {
    @EnvironmentObject var store: HabitStore

    private var snapshot: OrbitalFrameSnapshot { store.orbitalFrameSnapshot }

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let target = hitTest(at: location)
                    if store.hoveredTarget != target {
                        store.hoveredTarget = target
                    }
                    // Drive transient camera unless click-locked
                    if store.selectedPlanetId == nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            switch target {
                            case .planet(let catId):
                                store.orbitalFocus = .category(catId)
                            case .moon(let habitId, _):
                                store.orbitalFocus = .habit(habitId)
                            case .sun, .none:
                                store.orbitalFocus = .solarSystem
                            }
                        }
                    }
                case .ended:
                    store.hoveredTarget = .none
                    if store.selectedPlanetId == nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.orbitalFocus = .solarSystem
                        }
                    } else if let catId = store.selectedPlanetId {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.orbitalFocus = .planetDetail(catId)
                        }
                    }
                }
            }
            .onTapGesture { location in
                let target = hitTest(at: location)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    switch target {
                    case .planet(let catId):
                        if store.selectedPlanetId == catId {
                            // Tap same planet again → deselect
                            store.selectedPlanetId = nil
                            store.orbitalFocus = .solarSystem
                        } else {
                            store.selectedPlanetId = catId
                            store.orbitalFocus = .planetDetail(catId)
                        }
                    case .moon(_, let catId):
                        if store.selectedPlanetId == catId {
                            store.selectedPlanetId = nil
                            store.orbitalFocus = .solarSystem
                        } else {
                            store.selectedPlanetId = catId
                            store.orbitalFocus = .planetDetail(catId)
                        }
                    case .sun, .none:
                        store.selectedPlanetId = nil
                        store.orbitalFocus = .solarSystem
                    }
                }
            }
    }

    // MARK: - Hit Testing

    /// Check moons first (smaller, on top), then planets, then sun.
    private func hitTest(at point: CGPoint) -> OrbitalHitTarget {
        let minHitRadius: CGFloat = 14

        // Moons
        for moon in snapshot.moons {
            let dist = hypot(point.x - moon.screenX, point.y - moon.screenY)
            let hitRadius = max(moon.screenRadius, minHitRadius)
            if dist < hitRadius {
                // Find the categoryId for this moon
                if let habit = store.habits.first(where: { $0.id == moon.id }),
                   let catId = habit.categoryId {
                    return .moon(habitId: moon.id, categoryId: catId)
                }
            }
        }

        // Planets
        for planet in snapshot.planets {
            let dist = hypot(point.x - planet.screenX, point.y - planet.screenY)
            let hitRadius = max(planet.screenRadius, minHitRadius)
            if dist < hitRadius {
                return .planet(planet.id)
            }
        }

        // Sun
        if let sun = snapshot.sun {
            let dist = hypot(point.x - sun.screenX, point.y - sun.screenY)
            let hitRadius = max(sun.screenRadius, minHitRadius)
            if dist < hitRadius {
                return .sun
            }
        }

        return .none
    }
}
