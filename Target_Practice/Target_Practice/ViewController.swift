//
//  ViewController.swift
//  Target_Practice
//
//  Created by Sam Yao on 12/2/23.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreMotion

import FocusNode
import SmartHitTest

extension ARSCNView: ARSmartHitTest {}

extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.focusNode.updateFocusNode()
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var freezeFrame: UIButton!
    
    @IBOutlet weak var arrowImageView: UIImageView!// TODO:: add in proper arrow implementation
    @IBOutlet weak var fireButton: UIButton! //connect to draw button
    
    var motionManager = CMMotionManager()
    var isFiring = false
    
    let focusNode = FocusSquare()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMotionManager()

        sceneView.frame = self.view.bounds
        self.sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        sceneView.delegate = self
        sceneView.showsStatistics = true

        self.focusNode.viewDelegate = sceneView
        sceneView.scene.rootNode.addChildNode(self.focusNode)
        
        if let scene = SCNScene(named: "arrow_larger.scn"){
            // Set the scene to the view
            sceneView.scene = scene
            print("arrow added")
        }
        
    }
    
    func setupMotionManager() {//motion for arrow
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            if let motion = motion {
                self.addArrow()
                //print("motion manager set")
            }
        }
    }
    
    func addArrow(){
        //let sphere = SCNNode(geometry: SCNCylinder(radius: 5, height: 3))
        
        // TODO - arrow = SCNScene(named: "arrow_larger.scn")
        // Should Add Arrow as separate objects.
        let arrow = SCNNode(geometry: SCNSphere(radius: 5))
        
        // add a red arrow
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        // that can bounce around the room environment
        let physics = SCNPhysicsBody(type: .dynamic,
                                     shape:SCNPhysicsShape(geometry: arrow.geometry!, options:nil))

        physics.isAffectedByGravity = true
        physics.friction = 1
        physics.restitution = 2.5
        physics.mass = 3
        
        
        arrow.geometry?.firstMaterial = material
//        arrow.position = cameraNode.position
        arrow.physicsBody = physics

        //sceneView.scene.rootNode.addChildNode(planeNode)
        sceneView.scene.rootNode.addChildNode(arrow)
    }
    
    //    func addArrow(_ motion: CMDeviceMotion) {//arrow drop
    //            let gravity = motion.gravity
    //            let rotation = atan2(gravity.x, gravity.y) - .pi
    //
    //            if isFiring {
    //                // Adjust arrow angle based on the device's motion
    //                let arrowRotation = CGFloat(rotation)
    //                arrowImageView.transform = CGAffineTransform(rotationAngle: arrowRotation)
    //            }
    //        }
    
    @IBAction func fireButtonPressed(_ sender: UIButton) {
            isFiring = true
        }

    @IBAction func fireButtonReleased(_ sender: UIButton) {
            isFiring = false
        /*
            if let node = arrow{
                var moveAction:SCNAction
                // TODO:: Add code to handle arrow release logic, e.g., launch arrow with calculated power.
                moveAction = SCNAction.moveBy(x: 0, y: 0, z: -0.25, duration: 0.25)
                
                node.runAction
            }
            */
        }
    
    @IBAction func handleTap(_ sender: UIButton) {
        
        // grab the current AR session frame from the scene, if possible
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        // setup some geometry for a simple plane
        // TODO - Change snapshot to be a constant size, not small
        // Create new SCPlane outside of this function
        // if nil; need to create SCNPlane and add node
        // else, update position
        let imagePlane = SCNPlane(width:sceneView.bounds.width/600,
                                  height:sceneView.bounds.height/600)
        
        // TODO - Add snapshot change distance

        imagePlane.firstMaterial?.diffuse.contents = sceneView.snapshot()
        imagePlane.firstMaterial?.lightingModel = .constant
        
        // add the node to the scene
        let planeNode = SCNNode(geometry:imagePlane)
        planeNode.name = "planeNode"
        sceneView.scene.rootNode.childNodes.filter({ $0.name == "planeNode" }).forEach({ $0.removeFromParentNode() })
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        // update the node to be a bit in front of the camera inside the AR session
        
        // step one create a translation transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -3
        translation.columns.0.x = 0
        translation.columns.0.y = -1
        translation.columns.1.x = -1
        translation.columns.1.y = 0
        //print(translation)
        
        
        // step two, apply translation relative to camera for the node
        planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }
}

