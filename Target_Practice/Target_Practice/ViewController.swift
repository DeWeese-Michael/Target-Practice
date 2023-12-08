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

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var freezeFrame: UIButton!
    
    @IBOutlet weak var arrowImageView: UIImageView!// TODO:: add in proper arrow implementation
    @IBOutlet weak var fireButton: UIButton!
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    var motionManager = CMMotionManager()
    var isFiring = false
    
    let focusNode = FocusSquare()
    var score = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupMotionManager()
        createArrowNode()
        shootArrow()
        
        sceneView.frame = self.view.bounds
        self.sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        self.focusNode.viewDelegate = sceneView
        sceneView.scene.rootNode.addChildNode(self.focusNode)
        
//        if let scene = SCNScene(named: "arrow_horizontal.scn"){
//            // Set the scene to the view
//            sceneView.scene = scene
//            print("arrow added")
//        }
        
    }
    
//        func setupMotionManager() {//motion for arrow
//            motionManager.deviceMotionUpdateInterval = 0.1
//            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
//                if let motion = motion {
//                    self.createArrowNode()
//                    //print("motion manager set")
//                }
//            }
//        }
    
    func shootArrow() {
        // Load the arrow scene
        guard let arrowScene = SCNScene(named: "arrow_horizontal.scn") else {
            print("Error: Unable to load arrow scene.")
            return
        }

        // Retrieve the arrow node from the scene
        guard let arrowNode = arrowScene.rootNode.childNode(withName: "Cone", recursively: true) else {
            print("Error: Unable to find arrow node in the scene.")
            return
        }

        // Set the initial position of the arrow node in front of the camera
        if let currentFrame = sceneView.session.currentFrame {
            // Get the camera's position and orientation
            var translation = matrix_identity_float4x4
            let arrowTransform = currentFrame.camera.transform * translation

            // Set the arrow node's transform
            arrowNode.simdTransform = arrowTransform

            // Add arrow node to the scene
            sceneView.scene.rootNode.addChildNode(arrowNode)

            // Apply a forward velocity to the arrow
            let arrowDirection = arrowTransform.columns.2
            let arrowVelocity = SCNVector3(arrowDirection.x * 5.0, arrowDirection.y * 5.0, arrowDirection.z * 5.0) // Adjust the speed

            arrowNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            arrowNode.physicsBody?.isAffectedByGravity = false
            arrowNode.physicsBody?.velocity = arrowVelocity

            arrowNode.physicsBody?.categoryBitMask = 0xFFFF
            arrowNode.physicsBody?.collisionBitMask = 0xFFFF
            arrowNode.physicsBody?.contactTestBitMask = 0xFFFF
        } else {
            print("Error: Unable to get current frame from AR session.")
        }
    }
    
    func createArrowNode() -> SCNNode? {
        // Load the arrow scene
        guard let arrowScene = SCNScene(named: "arrow_horizontal.scn") else {
            print("Error: Unable to load arrow scene.")
            return nil
        }

        // Retrieve the arrow node from the scene
        guard let arrowNode = arrowScene.rootNode.childNode(withName: "Cone", recursively: true) else {
            print("Error: Unable to find arrow node in the scene.")
            return nil
        }

        // Set the initial position of the arrow node in front of the camera
        if let currentFrame = sceneView.session.currentFrame {
        } else {
            print("Error: Unable to get current frame from AR session.")
        }

        return arrowNode
    }
    
    
//        func addArrow(){
//            //let sphere = SCNNode(geometry: SCNCylinder(radius: 5, height: 3))
//
//
//            // TODO - arrow = SCNScene(named: "arrow_larger.scn")
//            // Should Add Arrow as separate objects.
//            let arrow = SCNNode(geometry: SCNSphere(radius: 5))
//
//            // add a red arrow
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.red
//
//            // that can bounce around the room environment
//            let physics = SCNPhysicsBody(type: .dynamic,
//                                         shape:SCNPhysicsShape(geometry: arrow.geometry!, options:nil))
//
//            physics.isAffectedByGravity = true
//            physics.friction = 1
//            physics.restitution = 2.5
//            physics.mass = 3
//
//
//            arrow.geometry?.firstMaterial = material
//    //        arrow.position = cameraNode.position
//            arrow.physicsBody = physics
//
//            //sceneView.scene.rootNode.addChildNode(planeNode)
//            sceneView.scene.rootNode.addChildNode(arrow)
//        }
//
////    gravity function not being used yet
//            func handleDeviceMotion(_ motion: CMDeviceMotion) {//arrow drop
//                    let gravity = motion.gravity
//                    let rotation = atan2(gravity.x, gravity.y) - .pi
//
//                    if isFiring {
//                        // Adjust arrow angle based on the device's motion
//                        let arrowRotation = CGFloat(rotation)
//                        arrowImageView.transform = CGAffineTransform(rotationAngle: arrowRotation)
//                    }
//                }
    
    @IBAction func fireButtonPressed(_ sender: UIButton) {
        isFiring = true
    }
    
    func configureArrowNode(_ arrowNode: SCNNode) { //set launch and trajectory of arrow
        // Configure physics
        arrowNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: arrowNode, options: nil))
        arrowNode.physicsBody?.isAffectedByGravity = false
        arrowNode.physicsBody?.categoryBitMask = 1 // Set appropriate category bit mask
        
        // Set appearance properties
        arrowNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    }
    
    @IBAction func fireButtonReleased(_ sender: UIButton) { //draw and release arrow
        isFiring = false

            if let arrowNode = createArrowNode() {
                configureArrowNode(arrowNode)
    
                // Add the arrow node to the scene
                sceneView.scene.rootNode.addChildNode(arrowNode)
            }
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
        planeNode.name = "target"
        sceneView.scene.rootNode.childNodes.filter({ $0.name == "target" }).forEach({ $0.removeFromParentNode() })
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
    
    //Function that handles arrow/target contact
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
        func updateContact(){
            // Add
            self.score += 1
            
            DispatchQueue.main.async {
                self.updateScore()
            }
        }
        
        if let nameA = contact.nodeA.name,
            let nameB = contact.nodeB.name,
            nameA == "target" || nameB == "cone"{ //If the ball makes contact with the hoop or the backboard
            // remove basketball from the scene
            updateContact()
        }
        
        if let nameB = contact.nodeB.name,
           let nameA = contact.nodeA.name,
            nameB == "target" || nameA == "cone"{//If the ball makes contact with the hoop or the backboard
            
            updateContact()
        }
        
    }
    
    //Updates the score for the
    func updateScore(){
        //if(updating){return}
        // change the current object we are asking the participant to find
        
        scoreLabel.text = "\(self.score)"
        
        /*
        topLabel.layer.add(animation, forKey: animationKey)
        topLabel.text = "Mavericks: \(self.playerScore), Spurs: \(self.computerScore)"
        
        if(playerScore>=5 || computerScore>=5){
            // if here, End the game
            topLabel.layer.add(animation, forKey: animationKey)
            if playerScore > computerScore{
                topLabel.text = "Mavs Win! San Antonio is now a DFW Suburb!"
                topLabel.textColor = UIColor.systemBlue
            }else{
                topLabel.text = "Mavs Lose! San Antonio finally has something going for it!"
                topLabel.textColor = UIColor.black
            }

        }else{
            //updating = false
        }*/
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
