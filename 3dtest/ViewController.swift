//
//  ViewController.swift
//  3dtest
//
//  Created by Florian Wolpert on 24.12.20.
//

import UIKit
import SceneKit

class ViewController: UIViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    
    var colormapShader: String = ""
    var checkeredShader: String = ""
    var model: ModelData? = nil
    var mesh: SCNGeometry? = nil
    var centerOfScreen = CGPoint()
    var countMarker = 0
    var marker = Array(repeating: SCNVector3(), count: 3)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sceneSetup()
        centerOfScreen = sceneView.center
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        sceneView.delegate = self
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let sceneView = self.sceneView!

        // check what nodes are tapped
        let p = gestureRecognize.location(in: sceneView)
        var hits = sceneView.hitTest(p, options: [:])
        
        var hit = findHit(withName: "Model", in: hits)
        
        if (hit == nil) {
            //print("found nothing...")
            return
        }
        
        // Only 3 markers allowed
        if countMarker > 2 {
            sceneView.scene?.rootNode.enumerateChildNodes { (node , stop) in
                if node.name == "Marker" {
                    node.removeFromParentNode()
                }
            }
            countMarker = 0
        }
        
        let hitPos = hit?.worldCoordinates
        
        print("hit at \(hitPos!)")
        
        marker[countMarker] = hitPos!
        
        var sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial!.diffuse.contents = UIColor.blue
        var node = SCNNode(geometry: sphere)
        node.position = hitPos!
        node.name = "Marker"
        sceneView.scene?.rootNode.addChildNode(node)
        
        countMarker+=1
        
        var dl = SCNVector3()
        var dr = SCNVector3()
        var vp = SCNVector3()
        
        if countMarker >= 3 {
            for m in marker {
                if (hasMaxY(m)) {
                    vp = m
                } else if (hasMinX(m)) {
                    dl = m
                } else {
                    dr = m
                }
            }
            print("vp: ",vp)
            print("dl: ",dl)
            print("dr: ",dr)
            
            var line = SCNGeometry.lineFrom(vector: dl, toVector: dr)
            line.firstMaterial!.diffuse.contents = UIColor.blue
            node = SCNNode(geometry: line)
            node.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node)
            
            let m = (dl+dr)*0.5
            
            var rayStart = m
            var rayEnd = m
            rayStart.z = 0
            rayEnd.z = 1
            
            line = SCNGeometry.lineFrom(vector: rayStart, toVector: rayEnd)
            line.firstMaterial!.diffuse.contents = UIColor.blue
            node = SCNNode(geometry: line)
            node.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node)
            
            hits = (sceneView.scene?.rootNode.hitTestWithSegment(from: rayStart , to: rayEnd, options: [:]))!
            hit = findHit(withName: "Model", in: hits)
            
            //print("hit: ",hit)
            
            let dm = hit!.worldCoordinates
            
            sphere = SCNSphere(radius: 0.005)
            sphere.firstMaterial!.diffuse.contents = UIColor.red
            node = SCNNode(geometry: sphere)
            node.position = dm
            node.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node)
            
            
            var a = (dm.z - vp.z)
            var b = (dm.y - vp.y)
            
            let ti = atan(a/b)
            
            print(String(format: "Rumpfneigung: %.2fº",ti.inDegree()))
            
            var p = SCNVector3(dm.x,dm.y,vp.z)
            var triangle = SCNGeometry.triangle(vp,dm,p)
            node = SCNNode(geometry: triangle)
            node.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node)
            
            
            a = (dm.x - vp.x)
            b = (dm.y - vp.y)
            
            let tb = atan(a/b)
            
            print(String(format: "Lotabweichung: %.2fº",tb.inDegree()))
            
            p = SCNVector3(vp.x,dm.y,dm.z)
            triangle = SCNGeometry.triangle(vp,dm,p)
            triangle.firstMaterial!.diffuse.contents = UIColor.yellow
            node = SCNNode(geometry: triangle)
            node.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node)
            
            print(String(format: "Beckenhochstand: %.2fmm",abs(dl.y-dr.y)*1000.0))
            
            mesh!.firstMaterial!.diffuse.contents = UIColor(red: 254/255, green: 177/255, blue: 154/255, alpha: 0.4)
        }
    }
    
    private func hasMinX(_ p: SCNVector3) -> Bool {
        for m in marker {
            if m.x < p.x {
                return false
            }
        }
        return true
    }
    
    private func hasMaxY(_ p: SCNVector3) -> Bool {
        for m in marker {
            if m.y > p.y {
                return false
            }
        }
        return true
    }

    
    @IBAction func buttonPressed(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mesh!.shaderModifiers = [:]
            mesh!.firstMaterial!.diffuse.contents = UIColor(red: 254/255, green: 177/255, blue: 154/255, alpha: 0.8)
        case 1:
            mesh!.shaderModifiers = [:]
            mesh!.firstMaterial!.diffuse.contents = model?.colorImage
        case 2:
            mesh!.shaderModifiers = [.surface: colormapShader]
            mesh!.firstMaterial!.diffuse.contents = model?.colorImage
        case 3:
            mesh!.shaderModifiers = [.surface: checkeredShader]
            mesh!.firstMaterial!.diffuse.contents = model?.colorImage
        default:
            mesh!.shaderModifiers = [:]
            mesh!.firstMaterial!.diffuse.contents = UIColor(red: 254/255, green: 177/255, blue: 154/255, alpha: 0.8)
        }
    }
    
    // Search in hit array for named node
    private func findHit(withName searchName: String, in array: [SCNHitTestResult]) -> SCNHitTestResult?
    {
        for (_, hit) in array.enumerated()
        {
            if hit.node.name == searchName {
                return hit
            }
        }
        return nil
    }
    
    // Build initial Scene
    private func sceneSetup() {
        
        let scene = SCNScene()
        
        scene.background.contents = UIColor.darkGray
        sceneView.autoenablesDefaultLighting = true
        
        var shaderURL = Bundle.main.url(forResource: "colormap", withExtension: "shader")
        
        do {
            let shader = try String(contentsOf: shaderURL!)
            colormapShader = shader
        } catch {
            fatalError("Can't load colormap shader from bundle.")
        }
        
        shaderURL = Bundle.main.url(forResource: "checkered", withExtension: "shader")
        
        do {
            let shader = try String(contentsOf: shaderURL!)
            checkeredShader = shader
        } catch {
            fatalError("Can't load checkered shader from bundle.")
        }
        
        /*
         // Ambientes Licht
         let ambientLightNode = SCNNode()
         ambientLightNode.light = SCNLight()
         ambientLightNode.light!.type = SCNLight.LightType.ambient
         ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
         scene.rootNode.addChildNode(ambientLightNode)
         
         // Lichtquelle (gleichmässig aus einer Richtung?)
         let omniLightNode = SCNNode()
         omniLightNode.light = SCNLight()
         omniLightNode.light!.type = SCNLight.LightType.omni
         omniLightNode.light!.color = UIColor(white: 0.75, alpha: 1.0)
         omniLightNode.position = SCNVector3Make(0, 50, -50)
         scene.rootNode.addChildNode(omniLightNode)
         */
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: -1)
        cameraNode.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        cameraNode.camera?.zNear = 0
        //cameraNode.camera?.zFar = 2.0
        scene.rootNode.addChildNode(cameraNode)
        
        model = ModelData()
        // check for model == nil !!
        mesh = model!.generateMesh()
        mesh!.firstMaterial!.diffuse.contents = UIColor(red: 254/255, green: 177/255, blue: 154/255, alpha: 0.8)
        mesh!.firstMaterial!.specular.contents = UIColor.white
        
        let meshNode = SCNNode(geometry: mesh)
        meshNode.name = "Model"
        scene.rootNode.addChildNode(meshNode)
        
        //scene.rootNode.addChildNode(Origin())
        
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = true
        
    }
    
}
