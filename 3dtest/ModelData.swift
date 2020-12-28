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
    
    // Bounding box
    private var maxX: Float32 = -1000
    private var minX: Float32 = 1000
    private var maxY: Float32 = -1000
    private var minY: Float32 = 1000
    
    // Camera intrinsics
    private var fx: Float32 = 0
    private var fy: Float32 = 0
    private var cx: Float32 = 0
    private var cy: Float32 = 0
    
    // Camer euler angles
    private var euler: SCNVector3 = SCNVector3(0,0,0)
    
    // Simple constructor, loading demo data from json file
    init() {
        let asset = NSDataAsset(name: "ExampleScan", bundle: Bundle.main)
        let json: NSDictionary = try! JSONSerialization.jsonObject(with: asset!.data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        
        depthMap = json["depthMap"] as? [[Float32]] ?? [[]]
        let cameraIntrinsics = json["cameraIntrinsics"] as? [[Float32]] ?? [[]]
        
        let camWidth = (json["camImageResolution"] as! NSDictionary)["width"] as! Float32
        let camHeight = (json["camImageResolution"] as! NSDictionary)["height"] as! Float32
        
        let lidarWidth = (json["depthMapResolution"] as! NSDictionary)["width"] as! Float32
        let lidarHeight = (json["depthMapResolution"] as! NSDictionary)["height"] as! Float32
        
        let xScale = 1.0/camWidth * lidarWidth
        let yScale = 1.0/camHeight * lidarHeight
        
        let jsonEuler = (json["cameraEulerAngle"] as! NSDictionary)
        print(jsonEuler)
        
        euler.x = Float32((json["cameraEulerAngle"] as! NSDictionary)["x"] as! Double)
        euler.y = Float32((json["cameraEulerAngle"] as! NSDictionary)["y"] as! Double)
        euler.z = Float32((json["cameraEulerAngle"] as! NSDictionary)["z"] as! Double)
        
        fx = cameraIntrinsics[0][0] * xScale
        fy = cameraIntrinsics[1][1] * yScale
        cx = cameraIntrinsics[0][2] * xScale
        cy = cameraIntrinsics[1][2] * yScale
    }
    
    // Constructor which creates a point cloud from ARFrame
    init(from frame: ARFrame, clipAt maxDepth: Double) {
        guard let cvDepthMap = frame.smoothedSceneDepth?.depthMap else {
            print("Error, no depth map")
            return
        }
        let p = CVPixelBufferGetPixelFormatType(cvDepthMap)
        if p != kCVPixelFormatType_DepthFloat32 {
            print("Error, wrong depth map type")
            return
        }
        
        depthMap = cvDepthMap.exportAsArray()
        
        let camWidth = Float(frame.camera.imageResolution.width)
        let camHeight = Float(frame.camera.imageResolution.height)
        
        let lidarWidth = Float(CVPixelBufferGetWidth(cvDepthMap))
        let lidarHeight = Float(CVPixelBufferGetHeight(cvDepthMap))
        
        // scale camera intrinsics to size of lidar sensor
        let xScale = 1.0/camWidth * lidarWidth
        let yScale = 1.0/camHeight * lidarHeight
        
        fx = frame.camera.intrinsics[0][0] * xScale
        fy = frame.camera.intrinsics[1][1] * yScale
        cx = frame.camera.intrinsics[0][2] * xScale
        cy = frame.camera.intrinsics[1][2] * yScale
    }
    
    // generate the mesh from given depth data and the camera intrinsic
    func generateMesh(maxDepth: Float32) -> SCNGeometry {
        
        // reset array
        triangleIndices = []
        
        // need to flip depthMap?
        let h = depthMap.count
        let w = depthMap[0].count
        
        //print("w = \(w), h = \(h)")
        
        // init 2d matrix of indices. Every index points to an 3d vertice. the x and y coordinates of the 3d vertices are aligned to the 2d matrix.
        idxMatrix = Array(repeating: Array(repeating: nil, count: h), count: w)
        
        //print(idxMatrix.count)
        //print(idxMatrix[0].count)
        
        // traverse the 2d depthMap. Calculate 3d points from the position of the depth value in the depth map in respect to the camera intrinsics
        var idx:Int32 = 0
        for ix in 0..<w {
            for iy in 0..<h {
                let z = depthMap[h-iy-1][ix] // swap x and y axis and the invert y axis (origin of the depth sensor (0,0) is upper left and y axis points downwards. In 3d space the y axis points upwards
                
                if (z < maxDepth) {  // depth clipping
                    
                    let x = z * (Float32(ix) - cx) / fx
                    let y = z * (Float32(iy) - cy) / fy
                    let point: SCNVector3 = SCNVector3(x, y, z)
                    
                    vertices.append(point) // add calculated point
                    normals.append(SCNVector3(x:0,y:0,z:0)) // create an empty normal element
                    idxMatrix[ix][iy] = idx  // store corresponding index
                    idx+=1  // prepare for next index
                    
                    // construct bounding box. Used later to center the point cloud
                    maxX = (x > maxX) ? x : maxX
                    minX = (x < minX) ? x : minX
                    maxY = (y > maxY) ? y : maxY
                    minY = (y < minY) ? y : minY
                }
            }
        }
        
        // Center point cloud in x/y plane
        // Calculate translation needed to center the point cloud in the world origin. Do the transformation only for the x and y axis. The z values remain untouched
        let originX = (maxX - minX)/2 + minX
        let originY = (maxY - minY)/2 + minY
        
        let shift = SCNVector3(-originX, -originY, 0)
        for index in vertices.indices {
            vertices[index] += shift
        }
        
        print("total points \(w*h), valid points \(idx)")
        
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
