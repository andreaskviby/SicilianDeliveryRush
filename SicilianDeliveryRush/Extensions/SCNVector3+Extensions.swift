import SceneKit
import simd

extension SCNVector3 {
    init(_ v: simd_float3) {
        self.init(x: Float(v.x), y: Float(v.y), z: Float(v.z))
    }

    var simd: simd_float3 {
        simd_float3(Float(x), Float(y), Float(z))
    }

    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    var length: Float {
        sqrt(x * x + y * y + z * z)
    }

    var normalized: SCNVector3 {
        let len = length
        guard len > 0 else { return self }
        return SCNVector3(x / len, y / len, z / len)
    }

    func distance(to other: SCNVector3) -> Float {
        (self - other).length
    }

    static func lerp(_ a: SCNVector3, _ b: SCNVector3, t: Float) -> SCNVector3 {
        a + (b - a) * t
    }
}

extension simd_float3 {
    var scnVector3: SCNVector3 {
        SCNVector3(x, y, z)
    }
}

extension SCNNode {
    var simdWorldFront: simd_float3 {
        simd_float3(
            -simdWorldTransform.columns.2.x,
            -simdWorldTransform.columns.2.y,
            -simdWorldTransform.columns.2.z
        )
    }

    var simdWorldRight: simd_float3 {
        simd_float3(
            simdWorldTransform.columns.0.x,
            simdWorldTransform.columns.0.y,
            simdWorldTransform.columns.0.z
        )
    }

    var simdWorldUp: simd_float3 {
        simd_float3(
            simdWorldTransform.columns.1.x,
            simdWorldTransform.columns.1.y,
            simdWorldTransform.columns.1.z
        )
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }

    func mapped(from: ClosedRange<Float>, to: ClosedRange<Float>) -> Float {
        let normalized = (self - from.lowerBound) / (from.upperBound - from.lowerBound)
        return to.lowerBound + normalized * (to.upperBound - to.lowerBound)
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
