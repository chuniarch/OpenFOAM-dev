// Vector2 — a 2D vector value type.
//
// The teaching app is 2D (the cavity case has an `empty` front/back patch),
// so a lightweight 2-component vector replaces OpenFOAM's `vector` (Vec3).

public struct Vector2: Equatable {
    public var x: Double
    public var y: Double

    public init(_ x: Double = 0, _ y: Double = 0) {
        self.x = x
        self.y = y
    }

    public static let zero = Vector2(0, 0)

    public var magnitude: Double { (x * x + y * y).squareRoot() }

    public func dot(_ o: Vector2) -> Double { x * o.x + y * o.y }

    public static func + (a: Vector2, b: Vector2) -> Vector2 { Vector2(a.x + b.x, a.y + b.y) }
    public static func - (a: Vector2, b: Vector2) -> Vector2 { Vector2(a.x - b.x, a.y - b.y) }
    public static prefix func - (a: Vector2) -> Vector2 { Vector2(-a.x, -a.y) }

    public static func * (s: Double, v: Vector2) -> Vector2 { Vector2(s * v.x, s * v.y) }
    public static func * (v: Vector2, s: Double) -> Vector2 { Vector2(v.x * s, v.y * s) }
    public static func / (v: Vector2, s: Double) -> Vector2 { Vector2(v.x / s, v.y / s) }

    public static func += (a: inout Vector2, b: Vector2) { a = a + b }
    public static func -= (a: inout Vector2, b: Vector2) { a = a - b }
}
