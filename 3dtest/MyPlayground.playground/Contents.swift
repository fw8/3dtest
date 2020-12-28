/*
import UIKit
import SceneKit

let scene = SCNScene()

let points = [
    SCNVector3Make(0, 0, 0),
    SCNVector3Make(0, 10, 0),
    SCNVector3Make(10, 0, 0),
]
let indices: [Int16] = [
    0,2,1,
]

let vertexSource = SCNGeometrySource(vertices: points)
let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
let geo = SCNGeometry(sources: [vertexSource], elements: [element])

*/

import SceneKit
import QuartzCore   // for the basic animation
import XCPlayground // for the live preview
import PlaygroundSupport

var scene = SCNScene()

let points = [
    SCNVector3(x: 0, y: 0, z: 0),
    SCNVector3Make(0, 1, 0),
    SCNVector3Make(1, 0, 0),
]

let indices: [Int16] = [
    0,2,1,
]

let normals = [
    SCNVector3Make(0, 1, 0),
    SCNVector3Make(0, 1, 1),
    SCNVector3Make(1, 0, 1),
    ]

let vertexSource = SCNGeometrySource(vertices: points)
let normalSource = SCNGeometrySource(normals: normals)
let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
let geo = SCNGeometry(sources: [vertexSource,normalSource], elements: [element])
let geoNode = SCNNode(geometry: geo)


// create a scene view with an empty scene
var sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))

sceneView.scene = scene

// start a live preview of that view
PlaygroundPage.current.liveView = sceneView

// default lighting
sceneView.autoenablesDefaultLighting = true

// a camera
var cameraNode = SCNNode()
cameraNode.camera = SCNCamera()
cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
cameraNode.eulerAngles = SCNVector3(x: 0, y: 0 , z: 0)
scene.rootNode.addChildNode(cameraNode)

// a geometry object
var torus = SCNTorus(ringRadius: 1, pipeRadius: 0.35)
var torusNode = SCNNode(geometry: torus)
//scene.rootNode.addChildNode(torusNode)

// configure the geometry object
torus.firstMaterial?.diffuse.contents  = UIColor.red   // (or UIColor on iOS)
torus.firstMaterial?.specular.contents = UIColor.white // (or UIColor on iOS)

scene.rootNode.addChildNode(geoNode)
geo.firstMaterial?.diffuse.contents = UIColor.green

// set a rotation axis (no angle) to be able to
// use a nicer keypath below and avoid needing
// to wrap it in an NSValue
torusNode.rotation = SCNVector4(x: 1.0, y: 1.0, z: 0.0, w: 0.0)

// animate the rotation of the torus
var spin = CABasicAnimation(keyPath: "rotation.w") // only animate the angle
spin.toValue = 2.0*Double.pi
spin.duration = 3
spin.repeatCount = HUGE // for infinity
torusNode.addAnimation(spin, forKey: "spin around")


