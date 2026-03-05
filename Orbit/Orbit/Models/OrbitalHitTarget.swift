import Foundation

enum OrbitalHitTarget: Equatable {
    case planet(UUID)
    case moon(habitId: UUID, categoryId: UUID)
    case sun
    case none
}

struct OrbitalFrameSnapshot: Equatable {
    struct Body: Equatable {
        let id: UUID
        let screenX: CGFloat
        let screenY: CGFloat
        let screenRadius: CGFloat
    }

    var sun: Body?
    var planets: [Body] = []
    var moons: [Body] = []
}
