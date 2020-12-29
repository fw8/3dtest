//
//  ModelData.swift
//  3dtest
//
//  Created by Florian Wolpert on 24.12.20.
//

import Foundation
import SceneKit
import ARKit

class ModelData {
    
    private var depthMap: [[Float32]] = [[]]    // 2d array of depth data from the lidar
    private var vertices: [SCNVector3] = []     // 3d vertices of the mesh covering the scanned object
    private var normals: [SCNVector3] = []      // normals for each vertice
    private var idxMatrix: [[Int32?]] = [[]]    // 2d array with pointers into the verices array
                                                // maps from lidar pixel to vertice in world coordinates
                                                // value could be nil if vertice was skiped or removed
    private var triangleIndices: [Int32] = []   // 1d list of indices pointing to triangle vertices
    
    // Camera intrinsics
    private var fx: Float32 = 0
    private var fy: Float32 = 0
    private var cx: Float32 = 0
    private var cy: Float32 = 0
    
    // Camer euler angles
    private var euler = simd_float3(0,0,0)
        
    // Simple constructor, loading demo data from json file
    init() {
        let asset = NSDataAsset(name: "ExampleScan", bundle: Bundle.main)
        let json: NSDictionary = try! JSONSerialization.jsonObject(with: asset!.data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        
        depthMap = json["depthMap"] as? [[Float32]] ?? [[]]
        let cameraIntrinsics = json["cameraIntrinsics"] as? [[Float32]] ?? [[]]
        
        
        // cam & lidar haben (scheinbar) immer querformat (landscape)
        // bei aufnahme im hochformat (portrait) geht die x achse dann also nach oben (oder nach unten)
        // das bild erscheint dann um 90 grad gedreht
        //
        // Quer (ausgangsformat):
        // Euler: x = -2º, y = 0º, z = -1º  also Handy quer, kamera links oben = (0,0,0)
        // Lidar: w = 256.0, h = 192.0, cx = 127.50073, cy = 91.79468
        //
        // Hochkant:
        // Euler: x = -4º, y = 0º, z = -90º  Handy hochkannt => kamera rechts oben = querformat um -90º um die z-achse gedreht
        // Lidar: w = 256.0, h = 192.0, cx = 123.33783, cy = 95.96991
        //
        // Euler positiv => drehung nach links, Euler negativ = drehung nach rechts
        
        
        let camWidth = (json["camImageResolution"] as! NSDictionary)["width"] as! Float32
        let camHeight = (json["camImageResolution"] as! NSDictionary)["height"] as! Float32
        
        let lidarWidth = (json["depthMapResolution"] as! NSDictionary)["width"] as! Float32
        let lidarHeight = (json["depthMapResolution"] as! NSDictionary)["height"] as! Float32
        
        let xScale = 1.0/camWidth * lidarWidth
        let yScale = 1.0/camHeight * lidarHeight
        
        euler.x = Float32((json["cameraEulerAngle"] as! NSDictionary)["x"] as! Double)
        euler.y = Float32((json["cameraEulerAngle"] as! NSDictionary)["y"] as! Double)
        euler.z = Float32((json["cameraEulerAngle"] as! NSDictionary)["z"] as! Double)
        
        print("Euler: x = \(Int(euler.x.inDegree().rounded()))º, y = \(Int(euler.y.inDegree().rounded()))º, z = \(Int(euler.z.inDegree().rounded()))º")
        
        fx = cameraIntrinsics[0][0] * xScale
        fy = cameraIntrinsics[1][1] * yScale
        cx = cameraIntrinsics[0][2] * xScale
        cy = cameraIntrinsics[1][2] * yScale
        
        print("Lidar: w = \(lidarWidth), h = \(lidarHeight), cx = \(cx), cy = \(cy)")
        
    }
    
    // Constructor which creates a point cloud from ARFrame
    init(_ frame: ARFrame?) {
        if (frame == nil) {
            print("Error, no frame")
            return
        }
        
        guard let cvDepthMap = frame!.smoothedSceneDepth?.depthMap else {
            print("Error, no depth map")
            return
        }
        let p = CVPixelBufferGetPixelFormatType(cvDepthMap)
        if p != kCVPixelFormatType_DepthFloat32 {
            print("Error, wrong depth map type")
            return
        }
        
        depthMap = cvDepthMap.exportAsArray()
        
        let camWidth = Float(frame!.camera.imageResolution.width)
        let camHeight = Float(frame!.camera.imageResolution.height)
        
        let lidarWidth = Float(CVPixelBufferGetWidth(cvDepthMap))
        let lidarHeight = Float(CVPixelBufferGetHeight(cvDepthMap))
        
        // scale camera intrinsics to size of lidar sensor
        let xScale = 1.0/camWidth * lidarWidth
        let yScale = 1.0/camHeight * lidarHeight
        
        fx = frame!.camera.intrinsics[0][0] * xScale
        fy = frame!.camera.intrinsics[1][1] * yScale
        cx = frame!.camera.intrinsics[0][2] * xScale
        cy = frame!.camera.intrinsics[1][2] * yScale

    }
    
    // generate the mesh from given depth data and the camera intrinsic
    func generateMesh(maxDepth: Float32 = 1.0) -> SCNGeometry {
        
        // reset array
        triangleIndices = []
        
        let w = depthMap.count
        let h = depthMap[0].count
        print("w = \(w), h = \(h)")
        
        // minimal z value of all vertices
        var minZ: Float32 = Float.greatestFiniteMagnitude
        
        // init 2d matrix of indices. Every index points to an 3d vertice. the x and y coordinates of the 3d vertices are aligned to the 2d matrix.
        idxMatrix = Array(repeating: Array(repeating: nil, count: h), count: w)
        
        //print(idxMatrix.count)
        //print(idxMatrix[0].count)
        
        // traverse the 2d depthMap. Calculate 3d points from the position of the depth value in the depth map in respect to the camera intrinsics
        var idx:Int32 = 0
        for ix in 0..<w {
            for iy in 0..<h {
                let z = depthMap[ix][iy] //
                
                if (z < maxDepth) {  // depth clipping assuming smalest z is 0
                    
                    let x = z * (Float32(ix) - cx) / fx
                    let y = z * (Float32(iy) - cy) / fy
                    
                    let point3d: SCNVector3 = SCNVector3(-1*x, -1*y, z).rotatedAround(y: -euler.x, z: euler.z)
                    // x und y achse spiegeln und euler.z um z achse drehen (weil wir bilder immer hochkannt machen ist euler.z immer ca. -90º)
                    // noch unklar warum die rotation von euler.x um die y achse... da stimmt irgendwas noch nicht
                    // coordinaten raum in sceneview ist: z zeigt zur kamera und die schaut nach -z, x nach rechts und y nach oben
                    // depth sensor schaut aber nach +z!
                    // aktuell wird die kamera einfach nach z=-1m verschoben und dann um 180º um die y achse gedreht
                    // danach zeigt die x achse allerdings nach links...
                    
                    vertices.append(point3d) // add calculated point
                    normals.append(SCNVector3(x:0,y:0,z:0)) // create an empty normal element
                    idxMatrix[ix][iy] = idx  // store corresponding index
                    idx+=1  // prepare for next index
                    
                    // compute smalest z value og point cloud
                    minZ = (point3d.z < minZ) ? point3d.z : minZ
                }
            }
        }
        
        // translation in direction of z, so that the smallest value of z is 0 afterwards
        for index in vertices.indices {
            vertices[index] += SCNVector3(0,0,-minZ)
        }
        
        print("total points: \(w*h), valid points: \(idx), minZ: \(minZ)")
        
        // generate 2 triangles for every vertex (but skip last row & column)
        for ix in 0..<w-1 {
            for iy in 0..<h-1 {
                genTriangle(idxMatrix[ix][iy],idxMatrix[ix][iy+1],idxMatrix[ix+1][iy])
                genTriangle(idxMatrix[ix+1][iy],idxMatrix[ix][iy+1],idxMatrix[ix+1][iy+1])
            }
        }
        
        
        // create data structures needed by SCNGeometry
    
        let vertexData = NSData(bytes: vertices, length: MemoryLayout<SCNVector3>.size * vertices.count) as Data
        
        let vertexSource = SCNGeometrySource(data: vertexData,
                                             semantic: .vertex,
                                             vectorCount: vertices.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SCNVector3>.stride)
        
        let normalData = NSData(bytes: normals, length: MemoryLayout<SCNVector3>.size * normals.count) as Data
        
        let normalSource = SCNGeometrySource(data: normalData,
                                             semantic: .normal,
                                             vectorCount: normals.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SCNVector3>.stride)
        
        let elementData = NSData(bytes: triangleIndices, length: MemoryLayout<Int32>.size * triangleIndices.count) as Data
        
        let element = SCNGeometryElement(data: elementData,
                                         primitiveType: .triangles,
                                         primitiveCount: triangleIndices.count/3,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        
        return SCNGeometry(sources: [vertexSource,normalSource], elements: [element])
        
    }
    
    // generate triangle from 3 points (given as index) and add the calculated normal to the vertices
    func genTriangle(_ p1:Int32?, _ p2:Int32?, _ p3:Int32?) {
        if (p1 == nil || p2 == nil || p3 == nil) {
            // generate no triangle if one or more vertices are nil (clipped away)
            return
        }
        triangleIndices.append(p1!)
        triangleIndices.append(p2!)
        triangleIndices.append(p3!)
        
        let n = calcNormal(p1!,p2!,p3!)
        
        // add normal of triangle to normal of all 3 vertices
        normals[Int(p1!)] += n
        normals[Int(p1!)].normalize()
        normals[Int(p2!)] += n
        normals[Int(p2!)].normalize()
        normals[Int(p3!)] += n
        normals[Int(p3!)].normalize()
    }
    
    // calculate normal of triangle
    func calcNormal(_ p1:Int32, _ p2:Int32, _ p3:Int32) -> SCNVector3
    {
        let vp1 = vertices[Int(p1)]
        let vp2 = vertices[Int(p2)]
        let vp3 = vertices[Int(p3)]
        
        let n = (vp2 - vp1).cross(vp3 - vp1)
        
        return(n.normalized())
    }
}


extension Float {
    func inDegree() -> Float {
        return self * 180 / .pi
    }
    
    func inRadians() -> Float {
        return self * .pi / 180
    }
}

