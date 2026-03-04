import SwiftUI

/// Halftone dot-matrix orbital system: each category is a planet orbiting a central sun,
/// with habit moons orbiting their category planet. Reacts to OrbitalFocus state with
/// smooth camera pan/zoom transitions driven by frame-by-frame lerping.
struct OrbitalSystemView: View {
    let habits: [Habit]
    let categories: [HabitCategory]
    let routines: [Routine]
    let selectedDate: Date
    let completionRate: Double
    let focus: OrbitalFocus

    // Grid constants
    private let cellSize: CGFloat = 6.5
    private let bgDarkness: CGFloat = 0.12

    // Camera: current (lerped each frame) and target
    @State private var camX: CGFloat = 0
    @State private var camY: CGFloat = 0
    @State private var camZoom: CGFloat = 1.0
    @State private var targetX: CGFloat = 0
    @State private var targetY: CGFloat = 0
    @State private var targetZoom: CGFloat = 1.0

    // Lerp speed (0→1, higher = faster catch-up)
    private let lerpRate: CGFloat = 0.08

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                drawScene(context: &context, size: size, time: time)
            }
        }
        .onChange(of: focus) { _, _ in
            // Target is recomputed each frame in drawScene based on focus + time
        }
    }

    // MARK: - Helpers

    /// Compute the world-space position of a category planet at a given time
    private func planetWorldPos(
        catIndex: Int, catCount: Int, time: Double,
        centerX: CGFloat, centerY: CGFloat, viewRadius: CGFloat
    ) -> (x: CGFloat, y: CGFloat, orbitRadius: CGFloat) {
        let orbitFraction = CGFloat(catIndex + 1) / CGFloat(catCount + 1)
        let orbitRadius = viewRadius * (0.30 + orbitFraction * 0.55)
        let speed = 0.3 / sqrt(Double(orbitFraction))
        let baseAngle = Double(catIndex) * (2.0 * .pi / Double(max(catCount, 1)))
        let angle = baseAngle + time * speed
        let px = centerX + CGFloat(cos(angle)) * orbitRadius
        let py = centerY + CGFloat(sin(angle)) * orbitRadius
        return (px, py, orbitRadius)
    }

    /// Compute the world-space position of a habit moon at a given time
    private func moonWorldPos(
        moonIndex: Int, moonCount: Int, time: Double,
        planetX: CGFloat, planetY: CGFloat, planetRadius: CGFloat
    ) -> (x: CGFloat, y: CGFloat) {
        let moonOrbitRadius = planetRadius * 1.8 + CGFloat(moonIndex) * cellSize * 1.5
        let moonSpeed = 0.8 / sqrt(Double(moonIndex + 1))
        let moonBaseAngle = Double(moonIndex) * (2.0 * .pi / Double(max(moonCount, 1)))
        let moonAngle = moonBaseAngle + time * moonSpeed
        let mx = planetX + CGFloat(cos(moonAngle)) * moonOrbitRadius
        let my = planetY + CGFloat(sin(moonAngle)) * moonOrbitRadius
        return (mx, my)
    }

    // MARK: - Drawing

    private func drawScene(context: inout GraphicsContext, size: CGSize, time: Double) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let viewRadius = min(size.width, size.height) / 2

        let sortedCategories = categories.sorted { $0.sortOrder < $1.sortOrder }
        let catCount = sortedCategories.count

        // --- Compute camera target dynamically based on focus + current time ---
        var newTargetX: CGFloat = 0
        var newTargetY: CGFloat = 0
        var newTargetZoom: CGFloat = 1.0

        switch focus {
        case .solarSystem, .routines, .weekly:
            break // defaults: center, zoom 1.0

        case .category(let catId):
            if let idx = sortedCategories.firstIndex(where: { $0.id == catId }) {
                let pos = planetWorldPos(catIndex: idx, catCount: catCount, time: time,
                                         centerX: centerX, centerY: centerY, viewRadius: viewRadius)
                newTargetX = pos.x
                newTargetY = pos.y
                newTargetZoom = 2.5
            }

        case .habit(let habitId):
            if let habit = habits.first(where: { $0.id == habitId }),
               let catId = habit.categoryId,
               let catIdx = sortedCategories.firstIndex(where: { $0.id == catId }) {
                let catHabits = habits.filter { $0.categoryId == catId }
                let catPos = planetWorldPos(catIndex: catIdx, catCount: catCount, time: time,
                                            centerX: centerX, centerY: centerY, viewRadius: viewRadius)
                let rate = catHabits.isEmpty ? 0.0 : CGFloat(catHabits.filter { $0.isCompleted(on: selectedDate) }.count) / CGFloat(catHabits.count)
                let planetRadius = (4 + rate * 4) * cellSize
                if let mi = catHabits.firstIndex(where: { $0.id == habitId }) {
                    let mPos = moonWorldPos(moonIndex: mi, moonCount: catHabits.count, time: time,
                                            planetX: catPos.x, planetY: catPos.y, planetRadius: planetRadius)
                    newTargetX = mPos.x
                    newTargetY = mPos.y
                    newTargetZoom = 3.5
                }
            }

        case .trends(let habitId):
            if let hid = habitId,
               let habit = habits.first(where: { $0.id == hid }),
               let catId = habit.categoryId,
               let catIdx = sortedCategories.firstIndex(where: { $0.id == catId }) {
                let pos = planetWorldPos(catIndex: catIdx, catCount: catCount, time: time,
                                         centerX: centerX, centerY: centerY, viewRadius: viewRadius)
                newTargetX = pos.x
                newTargetY = pos.y
                newTargetZoom = 2.5
            }
        }

        // Lerp camera toward target
        // For center (0,0) targets, use absolute screen center
        let absTargetX = newTargetZoom > 1.01 ? newTargetX : centerX
        let absTargetY = newTargetZoom > 1.01 ? newTargetY : centerY

        let newCamX = camX + (absTargetX - camX) * lerpRate
        let newCamY = camY + (absTargetY - camY) * lerpRate
        let newCamZoom = camZoom + (newTargetZoom - camZoom) * lerpRate

        // Update state (deferred to avoid modifying state during view update)
        DispatchQueue.main.async {
            camX = newCamX
            camY = newCamY
            camZoom = newCamZoom
        }

        // Use the lerped values for this frame
        let frameX = newCamX
        let frameY = newCamY
        let frameZoom = newCamZoom

        // --- Fill background ---
        context.fill(
            Rectangle().path(in: CGRect(origin: .zero, size: size)),
            with: .color(OrbitTheme.accent)
        )

        let cols = Int(size.width / cellSize)
        let rows = Int(size.height / cellSize)
        let gridOffsetX = (size.width - CGFloat(cols) * cellSize) / 2
        let gridOffsetY = (size.height - CGFloat(rows) * cellSize) / 2

        // Sun
        let sunRadius: CGFloat = 7 * cellSize
        let sunPulse = 1.0 + 0.08 * sin(time * 1.5) * (0.5 + completionRate * 0.5)
        let effectiveSunRadius = sunRadius * sunPulse

        // --- Precompute planet (category) screen positions ---
        struct PlanetInfo {
            let categoryId: UUID
            let worldX: CGFloat; let worldY: CGFloat
            let screenX: CGFloat; let screenY: CGFloat
            let screenRadius: CGFloat
            let orbitRadius: CGFloat
            let screenOrbitRadius: CGFloat
            let completionRate: CGFloat
        }

        var planets: [PlanetInfo] = []
        for (i, cat) in sortedCategories.enumerated() {
            let catHabits = habits.filter { $0.categoryId == cat.id }
            let pos = planetWorldPos(catIndex: i, catCount: catCount, time: time,
                                     centerX: centerX, centerY: centerY, viewRadius: viewRadius)
            let rate = catHabits.isEmpty ? 0.0 : CGFloat(catHabits.filter { $0.isCompleted(on: selectedDate) }.count) / CGFloat(catHabits.count)
            let planetRadius = (4 + rate * 4) * cellSize

            // Transform world → screen via camera
            let sx = (pos.x - frameX) * frameZoom + centerX
            let sy = (pos.y - frameY) * frameZoom + centerY
            let sr = planetRadius * frameZoom

            planets.append(PlanetInfo(
                categoryId: cat.id,
                worldX: pos.x, worldY: pos.y,
                screenX: sx, screenY: sy,
                screenRadius: sr,
                orbitRadius: pos.orbitRadius,
                screenOrbitRadius: pos.orbitRadius * frameZoom,
                completionRate: rate
            ))
        }

        // --- Precompute moon (habit) screen positions ---
        struct MoonInfo {
            let habitId: UUID
            let screenX: CGFloat; let screenY: CGFloat
            let screenRadius: CGFloat
            let completedToday: Bool
            let worldX: CGFloat; let worldY: CGFloat
        }

        var moons: [MoonInfo] = []
        for planet in planets {
            let catHabits = habits.filter { $0.categoryId == planet.categoryId }
            let rate = planet.completionRate
            let planetWorldRadius = ((4 + rate * 4) * cellSize)
            for (mi, habit) in catHabits.enumerated() {
                let mPos = moonWorldPos(moonIndex: mi, moonCount: catHabits.count, time: time,
                                        planetX: planet.worldX, planetY: planet.worldY,
                                        planetRadius: planetWorldRadius)
                let habitRate = CGFloat(habit.completionRate(days: 7))
                let moonWorldRadius = (1.5 + habitRate * 2) * cellSize

                let sx = (mPos.x - frameX) * frameZoom + centerX
                let sy = (mPos.y - frameY) * frameZoom + centerY
                let sr = moonWorldRadius * frameZoom

                moons.append(MoonInfo(
                    habitId: habit.id,
                    screenX: sx, screenY: sy,
                    screenRadius: sr,
                    completedToday: habit.isCompleted(on: selectedDate),
                    worldX: mPos.x, worldY: mPos.y
                ))
            }
        }

        // Sun screen position
        let sunSX = (centerX - frameX) * frameZoom + centerX
        let sunSY = (centerY - frameY) * frameZoom + centerY
        let sunSR = effectiveSunRadius * frameZoom

        // --- Focus modifiers ---
        let focusedCategoryId: UUID? = {
            if case .category(let id) = focus { return id }
            return nil
        }()
        let focusedHabitId: UUID? = {
            switch focus {
            case .habit(let id): return id
            case .trends(let id): return id
            default: return nil
            }
        }()
        let isRoutineFocus = focus == .routines
        let isWeeklyFocus = focus == .weekly

        let routineHabitIds: Set<UUID> = {
            guard isRoutineFocus else { return [] }
            var ids = Set<UUID>()
            for routine in routines {
                for step in routine.steps {
                    if let hid = step.habitId { ids.insert(hid) }
                }
            }
            return ids
        }()
        let scheduledTodayIds: Set<UUID> = {
            guard isWeeklyFocus else { return [] }
            return Set(habits.filter { $0.isScheduled(on: selectedDate) }.map { $0.id })
        }()

        // --- Render grid ---
        for row in 0..<rows {
            for col in 0..<cols {
                let x = gridOffsetX + CGFloat(col) * cellSize + cellSize / 2
                let y = gridOffsetY + CGFloat(row) * cellSize + cellSize / 2

                var darkness: CGFloat = bgDarkness

                // Orbit rings (in screen space)
                for planet in planets {
                    let distToSun = hypot(x - sunSX, y - sunSY)
                    let ringDelta = abs(distToSun - planet.screenOrbitRadius)
                    let ringThickness = cellSize * 1.2
                    if ringDelta < ringThickness {
                        let ringStrength = 1.0 - ringDelta / ringThickness
                        var ringDarkness: CGFloat = 0.15 * ringStrength + bgDarkness
                        if let fc = focusedCategoryId, planet.categoryId != fc { ringDarkness *= 0.4 }
                        if isRoutineFocus { ringDarkness *= 0.5 }
                        darkness = max(darkness, ringDarkness)
                    }
                }

                // Sun SDF
                let sunDist = hypot(x - sunSX, y - sunSY)
                if sunDist < sunSR {
                    let nx = (x - sunSX) / sunSR
                    let ny = (y - sunSY) / sunSR
                    let nz = sqrt(max(0, 1 - nx * nx - ny * ny))
                    let light = max(0, -0.4 * nx - 0.5 * ny + 0.6 * nz)
                    var brightness: CGFloat = 1.0
                    if case .trends = focus { brightness = 0.7 + CGFloat(completionRate) * 0.3 }
                    let sd = (0.5 + light * 0.4) * brightness
                    darkness = max(darkness, sd * (1.0 - sunDist / sunSR * 0.2))
                }

                // Planet SDFs
                for planet in planets {
                    let dist = hypot(x - planet.screenX, y - planet.screenY)
                    let pr = planet.screenRadius

                    var dim: CGFloat = 1.0
                    if let fc = focusedCategoryId, planet.categoryId != fc { dim = 0.25 }
                    if isWeeklyFocus {
                        let catHabits = habits.filter { $0.categoryId == planet.categoryId }
                        let hasScheduled = catHabits.contains { scheduledTodayIds.contains($0.id) }
                        dim = hasScheduled ? 1.0 : 0.25
                    }
                    if isRoutineFocus {
                        let catHabits = habits.filter { $0.categoryId == planet.categoryId }
                        let hasRoutineHabit = catHabits.contains { routineHabitIds.contains($0.id) }
                        dim = hasRoutineHabit ? 1.0 : 0.3
                    }

                    // Focus highlight ring
                    if focusedCategoryId == planet.categoryId {
                        if dist < pr * 2.0 && dist > pr * 1.2 {
                            let ht = (dist - pr * 1.2) / (pr * 0.8)
                            darkness = max(darkness, 0.45 * (1.0 - ht))
                        }
                    }

                    // Completion glow ring
                    if planet.completionRate > 0.5 && dist < pr * 1.5 && dist > pr {
                        let gt = (dist - pr) / (pr * 0.5)
                        darkness = max(darkness, 0.25 * (1.0 - gt) * dim)
                    }

                    // Planet body
                    if dist < pr {
                        let nx = (x - planet.screenX) / pr
                        let ny = (y - planet.screenY) / pr
                        let nz = sqrt(max(0, 1 - nx * nx - ny * ny))
                        let light = max(0, -0.4 * nx - 0.5 * ny + 0.6 * nz)
                        let pd = (0.4 + light * 0.5) * dim
                        let edgeFade = 1.0 - pow(dist / pr, 3)
                        darkness = max(darkness, pd * edgeFade)
                    }
                }

                // Moon SDFs — always visible when zoomed, or when focused
                let showMoons = frameZoom > 1.3
                for moon in moons {
                    let dist = hypot(x - moon.screenX, y - moon.screenY)
                    let mr = moon.screenRadius

                    let isFocused = focusedHabitId == moon.habitId

                    // At default zoom, only show focused moon
                    guard showMoons || isFocused else { continue }

                    var dim: CGFloat = 1.0
                    if isRoutineFocus && !routineHabitIds.contains(moon.habitId) { dim = 0.15 }
                    if isWeeklyFocus && !scheduledTodayIds.contains(moon.habitId) { dim = 0.25 }

                    // Focus highlight ring (bright, pulsing)
                    if isFocused {
                        let pulseScale: CGFloat = 1.0 + 0.15 * CGFloat(sin(time * 3.0))
                        let highlightOuter = mr * 2.2 * pulseScale
                        if dist < highlightOuter && dist > mr * 1.1 {
                            let ht = (dist - mr * 1.1) / (highlightOuter - mr * 1.1)
                            darkness = max(darkness, 0.5 * (1.0 - ht))
                        }
                    }

                    // Completion glow
                    if moon.completedToday && dist < mr * 1.6 && dist > mr {
                        let gt = (dist - mr) / (mr * 0.6)
                        darkness = max(darkness, 0.3 * (1.0 - gt) * dim)
                    }

                    // Moon body
                    if dist < mr {
                        let nx = (x - moon.screenX) / mr
                        let ny = (y - moon.screenY) / mr
                        let nz = sqrt(max(0, 1 - nx * nx - ny * ny))
                        let light = max(0, -0.4 * nx - 0.5 * ny + 0.6 * nz)
                        let md = (0.35 + light * 0.5) * dim
                        let edgeFade = 1.0 - pow(dist / mr, 3)
                        darkness = max(darkness, md * edgeFade)
                    }
                }

                // Routine connecting lines
                if isRoutineFocus {
                    for routine in routines {
                        let linked = routine.steps.compactMap { step -> MoonInfo? in
                            guard let hid = step.habitId else { return nil }
                            return moons.first { $0.habitId == hid }
                        }
                        guard linked.count >= 2 else { continue }

                        for i in 0..<(linked.count - 1) {
                            let m1 = linked[i], m2 = linked[i + 1]
                            let lineLen = hypot(m2.screenX - m1.screenX, m2.screenY - m1.screenY)
                            guard lineLen > 0 else { continue }
                            let dx = (m2.screenX - m1.screenX) / lineLen
                            let dy = (m2.screenY - m1.screenY) / lineLen
                            let t = max(0, min(lineLen, (x - m1.screenX) * dx + (y - m1.screenY) * dy))
                            let cx = m1.screenX + dx * t
                            let cy = m1.screenY + dy * t
                            let distToLine = hypot(x - cx, y - cy)

                            if distToLine < cellSize * 2.0 {
                                let dashPhase = t / (cellSize * 3)
                                if (dashPhase - floor(dashPhase)) < 0.5 {
                                    let ld = 0.35 * (1.0 - distToLine / (cellSize * 2.0))
                                    darkness = max(darkness, ld)
                                }
                            }
                        }
                    }
                }

                darkness = min(darkness, 1.0)

                let cellOrigin = CGPoint(
                    x: gridOffsetX + CGFloat(col) * cellSize,
                    y: gridOffsetY + CGFloat(row) * cellSize
                )
                HalftoneRenderer.drawDot(
                    in: &context,
                    cellOrigin: cellOrigin,
                    cellSize: cellSize,
                    darkness: darkness
                )
            }
        }
    }
}

/// Scattered pixel stars background
struct StarsBackgroundView: View {
    let starCount = 60

    var body: some View {
        Canvas { context, size in
            var rng = StableRNG(seed: 42)
            for _ in 0..<starCount {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let s = CGFloat.random(in: 1.5...3.0, using: &rng)
                let alpha = Double.random(in: 0.15...0.4, using: &rng)
                let rect = CGRect(x: x, y: y, width: s, height: s)
                context.fill(
                    RoundedRectangle(cornerRadius: 0.5).path(in: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
    }
}

struct StableRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
