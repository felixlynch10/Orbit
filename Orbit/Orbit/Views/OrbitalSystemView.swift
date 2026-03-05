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
    @Binding var frameSnapshot: OrbitalFrameSnapshot

    // Grid constants
    private let cellSize: CGFloat = 6.5
    private let bgDarkness: CGFloat = 0.12

    // Camera: current (lerped each frame)
    @State private var camX: CGFloat = 0
    @State private var camY: CGFloat = 0
    @State private var camZoom: CGFloat = 1.0
    @State private var lastFrameTime: Double = 0

    private let sunId = UUID()

    // Exponential decay half-life in seconds (lower = snappier)
    private let smoothingHalfLife: Double = 0.12

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
        let orbitRadius = viewRadius * (0.40 + orbitFraction * 0.75)
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

        case .planetDetail(let catId):
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
                let planetRadius: CGFloat = 3 * cellSize
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

        // Smooth camera with time-based exponential decay
        let absTargetX = newTargetZoom > 1.01 ? newTargetX : centerX
        let absTargetY = newTargetZoom > 1.01 ? newTargetY : centerY

        // Compute delta-time based decay factor
        let dt = lastFrameTime > 0 ? min(time - lastFrameTime, 0.1) : 1.0 / 30.0
        let decay = CGFloat(pow(2.0, -dt / smoothingHalfLife))
        let snapThreshold: CGFloat = 0.5 // snap when close enough to avoid micro-oscillation

        var frameX = camX * decay + absTargetX * (1 - decay)
        var frameY = camY * decay + absTargetY * (1 - decay)
        var frameZoom = camZoom * decay + newTargetZoom * (1 - decay)

        // Snap to target when very close
        if abs(frameX - absTargetX) < snapThreshold { frameX = absTargetX }
        if abs(frameY - absTargetY) < snapThreshold { frameY = absTargetY }
        if abs(frameZoom - newTargetZoom) < 0.005 { frameZoom = newTargetZoom }

        // Write back for next frame (deferred to avoid state mutation during render)
        DispatchQueue.main.async {
            camX = frameX
            camY = frameY
            camZoom = frameZoom
            lastFrameTime = time
        }

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
            let planetRadius: CGFloat = 3 * cellSize

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
            let categoryId: UUID
            let screenX: CGFloat; let screenY: CGFloat
            let screenRadius: CGFloat
            let completedToday: Bool
            let worldX: CGFloat; let worldY: CGFloat
            let colorName: String
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
                    categoryId: planet.categoryId,
                    screenX: sx, screenY: sy,
                    screenRadius: sr,
                    completedToday: habit.isCompleted(on: selectedDate),
                    worldX: mPos.x, worldY: mPos.y,
                    colorName: habit.colorName
                ))
            }
        }

        // Sun screen position
        let sunSX = (centerX - frameX) * frameZoom + centerX
        let sunSY = (centerY - frameY) * frameZoom + centerY
        let sunSR = effectiveSunRadius * frameZoom

        // Publish frame snapshot for hit-testing overlay
        DispatchQueue.main.async {
            var snap = OrbitalFrameSnapshot()
            snap.sun = .init(id: sunId, screenX: sunSX, screenY: sunSY, screenRadius: sunSR)
            snap.planets = planets.map {
                .init(id: $0.categoryId, screenX: $0.screenX, screenY: $0.screenY, screenRadius: $0.screenRadius)
            }
            snap.moons = moons.map {
                .init(id: $0.habitId, screenX: $0.screenX, screenY: $0.screenY, screenRadius: $0.screenRadius)
            }
            frameSnapshot = snap
        }

        // --- Focus modifiers ---
        let focusedCategoryId: UUID? = {
            switch focus {
            case .category(let id): return id
            case .planetDetail(let id): return id
            default: return nil
            }
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
        let hasFocus = focusedCategoryId != nil || focusedHabitId != nil

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

        // --- Reticle target position (screen space) ---
        // Find the primary focus target's screen position for crosshairs
        var reticleX: CGFloat = 0
        var reticleY: CGFloat = 0
        var reticleRadius: CGFloat = 0
        var hasReticle = false

        if let fcId = focusedCategoryId {
            if let planet = planets.first(where: { $0.categoryId == fcId }) {
                reticleX = planet.screenX
                reticleY = planet.screenY
                reticleRadius = planet.screenRadius
                hasReticle = true
            }
        }
        if let fhId = focusedHabitId {
            if let moon = moons.first(where: { $0.habitId == fhId }) {
                reticleX = moon.screenX
                reticleY = moon.screenY
                reticleRadius = moon.screenRadius
                hasReticle = true
            } else if focusedCategoryId == nil {
                // Trend focus on habit — find its category planet as fallback
                if let habit = habits.first(where: { $0.id == fhId }),
                   let catId = habit.categoryId,
                   let planet = planets.first(where: { $0.categoryId == catId }) {
                    reticleX = planet.screenX
                    reticleY = planet.screenY
                    reticleRadius = planet.screenRadius
                    hasReticle = true
                }
            }
        }

        // Reticle geometry
        let bracketSize = max(reticleRadius * 2.5, cellSize * 8)
        let bracketThickness = cellSize * 1.0
        let bracketCornerLen = bracketSize * 0.3
        let crosshairGap = reticleRadius * 1.6 // gap around the target so lines don't overlap it
        let crosshairThickness = cellSize * 0.9

        // Category color lookup for tinting
        // Tinted colors: blend 30% category color with 70% base dot color
        // so planets stay in the halftone aesthetic but are distinguishable
        let baseR: CGFloat = 0.18, baseG: CGFloat = 0.20, baseB: CGFloat = 0.05
        let tintMix: CGFloat = 0.35
        let categoryColors: [UUID: Color] = Dictionary(
            uniqueKeysWithValues: sortedCategories.map { cat -> (UUID, Color) in
                let c = NSColor(OrbitTheme.color(for: cat.colorName))
                    .usingColorSpace(.sRGB) ?? NSColor(red: baseR, green: baseG, blue: baseB, alpha: 1)
                let r = baseR * (1 - tintMix) + c.redComponent * tintMix
                let g = baseG * (1 - tintMix) + c.greenComponent * tintMix
                let b = baseB * (1 - tintMix) + c.blueComponent * tintMix
                return (cat.id, Color(red: r, green: g, blue: b))
            }
        )

        // --- Render grid ---
        for row in 0..<rows {
            for col in 0..<cols {
                let x = gridOffsetX + CGFloat(col) * cellSize + cellSize / 2
                let y = gridOffsetY + CGFloat(row) * cellSize + cellSize / 2

                var darkness: CGFloat = bgDarkness
                var dotColor: Color = HalftoneRenderer.dotColor

                // Global dimming when a target is focused
                let globalDim: CGFloat = hasFocus ? 0.06 : bgDarkness
                darkness = globalDim

                // Orbit rings (in screen space)
                for planet in planets {
                    let distToSun = hypot(x - sunSX, y - sunSY)
                    let ringDelta = abs(distToSun - planet.screenOrbitRadius)
                    let ringThickness = cellSize * 1.2
                    if ringDelta < ringThickness {
                        let ringStrength = 1.0 - ringDelta / ringThickness
                        var ringDarkness: CGFloat = 0.15 * ringStrength + bgDarkness
                        if hasFocus {
                            // Only show focused planet's orbit ring prominently
                            let isFocusedRing = focusedCategoryId == planet.categoryId
                            ringDarkness *= isFocusedRing ? 1.2 : 0.3
                        }
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
                    if hasFocus { brightness *= 0.5 } // dim sun when targeting
                    let sd = (0.5 + light * 0.4) * brightness
                    darkness = max(darkness, sd * (1.0 - sunDist / sunSR * 0.2))
                }

                // Planet SDFs
                for planet in planets {
                    let dist = hypot(x - planet.screenX, y - planet.screenY)
                    let pr = planet.screenRadius

                    var dim: CGFloat = 1.0
                    if let fc = focusedCategoryId, planet.categoryId != fc { dim = 0.15 }
                    if focusedHabitId != nil && focusedCategoryId == nil {
                        // Habit-level focus: dim all planets except the parent
                        if let fhId = focusedHabitId,
                           let habit = habits.first(where: { $0.id == fhId }),
                           habit.categoryId != planet.categoryId {
                            dim = 0.15
                        }
                    }
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
                        if let catColor = categoryColors[planet.categoryId] {
                            dotColor = catColor
                        }
                    }
                }

                // Moon SDFs — fade in smoothly based on zoom level
                let moonFade: CGFloat = min(max((frameZoom - 1.0) / 0.8, 0), 1)
                for moon in moons {
                    let dist = hypot(x - moon.screenX, y - moon.screenY)
                    let mr = moon.screenRadius
                    let isFocused = focusedHabitId == moon.habitId
                    let effectiveFade = isFocused ? 1.0 : moonFade

                    guard effectiveFade > 0.01 else { continue }

                    var dim: CGFloat = effectiveFade
                    if isRoutineFocus && !routineHabitIds.contains(moon.habitId) { dim *= 0.15 }
                    if isWeeklyFocus && !scheduledTodayIds.contains(moon.habitId) { dim *= 0.25 }
                    if focusedHabitId != nil && !isFocused { dim *= 0.2 }

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
                        let mc = NSColor(OrbitTheme.color(for: moon.colorName))
                            .usingColorSpace(.sRGB) ?? NSColor(red: baseR, green: baseG, blue: baseB, alpha: 1)
                        let mr2 = baseR * (1 - tintMix) + mc.redComponent * tintMix
                        let mg = baseG * (1 - tintMix) + mc.greenComponent * tintMix
                        let mb = baseB * (1 - tintMix) + mc.blueComponent * tintMix
                        dotColor = Color(red: mr2, green: mg, blue: mb)
                    }
                }

                // --- Targeting reticle ---
                if hasReticle {
                    let dx = x - reticleX
                    let dy = y - reticleY
                    let absDx = abs(dx)
                    let absDy = abs(dy)
                    let distToTarget = hypot(dx, dy)

                    // Crosshair lines: horizontal and vertical through target, with gap around it
                    // Dashed pattern for halftone feel
                    let dashPeriod = cellSize * 4
                    let dashDuty: CGFloat = 0.55

                    // Horizontal crosshair
                    if absDy < crosshairThickness && distToTarget > crosshairGap {
                        let dashPhase = abs(dx) / dashPeriod
                        let isDash = (dashPhase - floor(dashPhase)) < dashDuty
                        if isDash {
                            let fadeFromCenter = min(1.0, (distToTarget - crosshairGap) / (cellSize * 4))
                            let fadeFromEdge = max(0, 1.0 - absDx / (size.width * 0.45))
                            let lineStrength = 0.55 * fadeFromCenter * fadeFromEdge * (1.0 - absDy / crosshairThickness)
                            darkness = max(darkness, lineStrength)
                        }
                    }

                    // Vertical crosshair
                    if absDx < crosshairThickness && distToTarget > crosshairGap {
                        let dashPhase = abs(dy) / dashPeriod
                        let isDash = (dashPhase - floor(dashPhase)) < dashDuty
                        if isDash {
                            let fadeFromCenter = min(1.0, (distToTarget - crosshairGap) / (cellSize * 4))
                            let fadeFromEdge = max(0, 1.0 - absDy / (size.height * 0.45))
                            let lineStrength = 0.55 * fadeFromCenter * fadeFromEdge * (1.0 - absDx / crosshairThickness)
                            darkness = max(darkness, lineStrength)
                        }
                    }

                    // Corner brackets: 4 L-shaped corners around the target
                    let halfBracket = bracketSize / 2
                    let corners: [(CGFloat, CGFloat)] = [
                        (reticleX - halfBracket, reticleY - halfBracket), // top-left
                        (reticleX + halfBracket, reticleY - halfBracket), // top-right
                        (reticleX - halfBracket, reticleY + halfBracket), // bottom-left
                        (reticleX + halfBracket, reticleY + halfBracket), // bottom-right
                    ]
                    for (ci, corner) in corners.enumerated() {
                        let cx = corner.0
                        let cy = corner.1
                        let relX = x - cx
                        let relY = y - cy

                        // Horizontal arm of the L
                        let hDir: CGFloat = (ci % 2 == 0) ? 1 : -1 // inward direction
                        let armX = relX * hDir
                        if abs(relY) < bracketThickness && armX >= 0 && armX < bracketCornerLen {
                            let strength: CGFloat = 0.7 * (1.0 - abs(relY) / bracketThickness)
                            darkness = max(darkness, strength)
                        }

                        // Vertical arm of the L
                        let vDir: CGFloat = (ci < 2) ? 1 : -1 // inward direction
                        let armY = relY * vDir
                        if abs(relX) < bracketThickness && armY >= 0 && armY < bracketCornerLen {
                            let strength: CGFloat = 0.7 * (1.0 - abs(relX) / bracketThickness)
                            darkness = max(darkness, strength)
                        }
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
                            let ldx = (m2.screenX - m1.screenX) / lineLen
                            let ldy = (m2.screenY - m1.screenY) / lineLen
                            let t = max(0, min(lineLen, (x - m1.screenX) * ldx + (y - m1.screenY) * ldy))
                            let cx = m1.screenX + ldx * t
                            let cy = m1.screenY + ldy * t
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
                    darkness: darkness,
                    color: dotColor
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
