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
    
    var colormapShader: String = ""
    var model: ModelData? = nil
    var mesh: SCNGeometry? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sceneSetup()
        
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
        default:
            mesh!.shaderModifiers = [:]
            mesh!.firstMaterial!.diffuse.contents = UIColor(red: 254/255, green: 177/255, blue: 154/255, alpha: 0.8)
        }
    }
    
    // MARK: Scene
    func sceneSetup() {
        // 1
        let scene = SCNScene()
        scene.background.contents = UIColor.darkGray
        sceneView.autoenablesDefaultLighting = true
        
        guard let shaderURL = Bundle.main.url(forResource: "colormap", withExtension: "shader"),
              let shader = try? String(contentsOf: shaderURL)
            else { fatalError("Can't load shader from bundle.") }
        colormapShader = shader
        
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
        // rotate texture 90º for portrait mode
//        let translation = SCNMatrix4MakeTranslation(0, -1, 0)
//        let rotation = SCNMatrix4MakeRotation(Float(90.0).inRadians(), 0, 0, 1)
//        let transform = SCNMatrix4Mult(translation, rotation)
        
//        mesh.firstMaterial?.diffuse.contentsTransform = transform
        //mesh.shaderModifiers = [.surface: stripesShader]
        mesh!.firstMaterial!.specular.contents = UIColor.white
        let meshNode = SCNNode(geometry: mesh)
        scene.rootNode.addChildNode(meshNode)
        
        //scene.rootNode.addChildNode(Origin())
        
        // 3
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = true
        
    }
    
}
