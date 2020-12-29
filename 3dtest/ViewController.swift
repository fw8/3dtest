//
//  ViewController.swift
//  3dtest
//
//  Created by Florian Wolpert on 24.12.20.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sceneSetup()
        
    }
    
    
    // MARK: Scene
    func sceneSetup() {
        // 1
        let scene = SCNScene()
        scene.background.contents = UIColor.darkGray
        sceneView.autoenablesDefaultLighting = true
        
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
        
        let x: ModelData
        x = ModelData()
        
        let mesh = x.generateMesh()
        mesh.firstMaterial!.diffuse.contents = UIColor.orange
        mesh.firstMaterial!.specular.contents = UIColor.white
        let meshNode = SCNNode(geometry: mesh)
        scene.rootNode.addChildNode(meshNode)
        
        scene.rootNode.addChildNode(Origin())
        
        // 3
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = true
        
    }
    
    
}

