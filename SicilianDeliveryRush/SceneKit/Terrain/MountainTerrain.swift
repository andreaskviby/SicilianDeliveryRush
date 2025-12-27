import SceneKit
import simd

final class MountainTerrain {
    let node: SCNNode

    private var heightMap: [[Float]] = []
    private var width: Int = 0
    private var depth: Int = 0
    private var maxHeight: Float = 0

    private var perm: [Int]

    init() {
        node = SCNNode()
        node.name = "terrain"

        var p = Array(0..<256)
        p.shuffle()
        perm = p + p
    }

    func generate(width: Int, depth: Int, maxHeight: Float) {
        self.width = width
        self.depth = depth
        self.maxHeight = maxHeight

        heightMap = generateHeightMap(width: width, depth: depth, maxHeight: maxHeight)

        let geometry = createTerrainGeometry()

        let material = createTerrainMaterial()
        geometry.materials = [material]

        node.geometry = geometry

        setupPhysics()
    }

    private func generateHeightMap(width: Int, depth: Int, maxHeight: Float) -> [[Float]] {
        var map: [[Float]] = Array(
            repeating: Array(repeating: 0, count: depth),
            count: width
        )

        let octaves = 4
        var amplitude: Float = 1.0
        var frequency: Float = 0.01
        var maxValue: Float = 0

        for _ in 0..<octaves {
            for x in 0..<width {
                for z in 0..<depth {
                    let nx = Float(x) * frequency
                    let nz = Float(z) * frequency
                    map[x][z] += perlinNoise(x: nx, z: nz) * amplitude
                }
            }
            maxValue += amplitude
            amplitude *= 0.5
            frequency *= 2.0
        }

        for x in 0..<width {
            for z in 0..<depth {
                var height = (map[x][z] / maxValue) * maxHeight

                let centerX = Float(width) / 2
                let centerZ = Float(depth) / 2
                let distFromCenter = sqrt(pow(Float(x) - centerX, 2) + pow(Float(z) - centerZ, 2))
                let maxDist = sqrt(centerX * centerX + centerZ * centerZ)
                let edgeFactor = 1.0 - (distFromCenter / maxDist)
                height *= edgeFactor

                let zProgress = Float(z) / Float(depth)
                height *= (1.0 - zProgress * 0.8)

                map[x][z] = height
            }
        }

        return map
    }

    private func perlinNoise(x: Float, z: Float) -> Float {
        let xi = Int(floor(x)) & 255
        let zi = Int(floor(z)) & 255
        let xf = x - floor(x)
        let zf = z - floor(z)

        let u = fade(xf)
        let v = fade(zf)

        let aa = perm[(perm[xi] + zi) & 255]
        let ab = perm[(perm[xi] + zi + 1) & 255]
        let ba = perm[(perm[(xi + 1) & 255] + zi) & 255]
        let bb = perm[(perm[(xi + 1) & 255] + zi + 1) & 255]

        let x1 = lerp(grad(aa, xf, zf), grad(ba, xf - 1, zf), u)
        let x2 = lerp(grad(ab, xf, zf - 1), grad(bb, xf - 1, zf - 1), u)

        return lerp(x1, x2, v)
    }

    private func fade(_ t: Float) -> Float {
        t * t * t * (t * (t * 6 - 15) + 10)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + t * (b - a)
    }

    private func grad(_ hash: Int, _ x: Float, _ z: Float) -> Float {
        let h = hash & 3
        let u = h < 2 ? x : z
        let v = h < 2 ? z : x
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }

    private func createTerrainGeometry() -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var texCoords: [CGPoint] = []
        var indices: [UInt32] = []

        for x in 0..<width {
            for z in 0..<depth {
                let height = heightMap[x][z]
                vertices.append(SCNVector3(Float(x) - Float(width)/2, height, Float(z) - Float(depth)/2))
                texCoords.append(CGPoint(x: Double(x) / 10.0, y: Double(z) / 10.0))
            }
        }

        for x in 0..<(width - 1) {
            for z in 0..<(depth - 1) {
                let topLeft = UInt32(x * depth + z)
                let topRight = UInt32((x + 1) * depth + z)
                let bottomLeft = UInt32(x * depth + z + 1)
                let bottomRight = UInt32((x + 1) * depth + z + 1)

                indices.append(contentsOf: [topLeft, bottomLeft, topRight])
                indices.append(contentsOf: [topRight, bottomLeft, bottomRight])
            }
        }

        normals = calculateNormals(vertices: vertices, indices: indices)

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let texCoordSource = SCNGeometrySource(textureCoordinates: texCoords)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

        return SCNGeometry(sources: [vertexSource, normalSource, texCoordSource], elements: [element])
    }

    private func calculateNormals(vertices: [SCNVector3], indices: [UInt32]) -> [SCNVector3] {
        var normals = Array(repeating: simd_float3(0, 0, 0), count: vertices.count)

        for i in stride(from: 0, to: indices.count, by: 3) {
            let i0 = Int(indices[i])
            let i1 = Int(indices[i + 1])
            let i2 = Int(indices[i + 2])

            let v0 = vertices[i0].simd
            let v1 = vertices[i1].simd
            let v2 = vertices[i2].simd

            let normal = simd_normalize(simd_cross(v1 - v0, v2 - v0))

            normals[i0] += normal
            normals[i1] += normal
            normals[i2] += normal
        }

        return normals.map { simd_normalize($0).scnVector3 }
    }

    private func createTerrainMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.4, green: 0.55, blue: 0.3, alpha: 1)
        material.roughness.contents = 0.9
        material.lightingModel = .physicallyBased

        return material
    }

    private func setupPhysics() {
        guard let geometry = node.geometry else { return }

        let shape = SCNPhysicsShape(geometry: geometry, options: [
            .type: SCNPhysicsShape.ShapeType.concavePolyhedron
        ])
        node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        node.physicsBody?.categoryBitMask = PhysicsCategory.terrain
        node.physicsBody?.friction = 0.9
    }

    func heightAt(x: Float, z: Float) -> Float {
        let adjustedX = x + Float(width) / 2
        let adjustedZ = z + Float(depth) / 2

        let xi = Int(adjustedX)
        let zi = Int(adjustedZ)

        guard xi >= 0, xi < width - 1, zi >= 0, zi < depth - 1 else {
            return 0
        }

        let xf = adjustedX - Float(xi)
        let zf = adjustedZ - Float(zi)

        let h00 = heightMap[xi][zi]
        let h10 = heightMap[xi + 1][zi]
        let h01 = heightMap[xi][zi + 1]
        let h11 = heightMap[xi + 1][zi + 1]

        let h0 = lerp(h00, h10, xf)
        let h1 = lerp(h01, h11, xf)

        return lerp(h0, h1, zf)
    }
}
