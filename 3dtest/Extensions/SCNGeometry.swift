//
//  SCNGeometry.swift
//  3dtest
//
//  Created by Flo on 06.03.21.
//

import Foundation
import SceneKit

extension SCNGeometry {
    static func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }

    static func triangle(_ p1: SCNVector3, _ p2: SCNVector3, _ p3: SCNVector3) -> SCNGeometry {

        let indices: [Int32] = [0, 1, 2]

        let source = SCNGeometrySource(vertices: [p1, p2, p3])
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        material.isDoubleSided = true
        geometry.firstMaterial = material
        return geometry
    }
}
