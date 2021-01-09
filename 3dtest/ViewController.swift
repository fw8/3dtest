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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sceneSetup()
        centerOfScreen = sceneView.center
        sceneView.delegate = self
        
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
    
    // Delegate function of SCNSceneRenderer
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // get cam pos and calc ray and move needle to intersection
        // what to do if there is no intersection?
        // align needle to surface normal?
        
        //let campos = sceneView.pointOfView?.worldPosition
        //print("campos: \(campos!)")
        
        let hits = sceneView.hitTest(centerOfScreen)
        let hit = findHit(withName: "Model", in: hits)
        
        if (hit == nil) {
            //print("found nothing...")
            return
        }
        
        let hitPos = hit?.worldCoordinates
        
        //print("hit at \(hitPos!)")
        
        var node = sceneView.scene?.rootNode.childNode(withName: "Marker", recursively: true)
        
        if (node == nil) {
            let sphere = SCNSphere(radius: 0.01)
            sphere.firstMaterial!.diffuse.contents = UIColor.red
            node = SCNNode(geometry: sphere)
            node?.position = hitPos!
            node?.name = "Marker"
            sceneView.scene?.rootNode.addChildNode(node!)
        }
        
        let action = SCNAction.move(to: hitPos!, duration: 0.1)
        node?.runAction(action)
        
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
