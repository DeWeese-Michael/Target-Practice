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
    var diff : Double = 0
    var isFiring = false
    var scene : SCNScene!
    var cameraNode : SCNNode!
    var planeNode : SCNNode!
    var arrowNode : SCNNode!
    var initialAttitude: (roll: Double, pitch:Double, yaw:Double)?
    let focusNode = FocusSquare()
    var score = 0
    var lastNode:SCNNode? = nil
    var startingPoint: Date?
    
    
    
    
    let animation = CATransition()
    let animationKey = convertFromCATransitionType(CATransitionType.push)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupMotionManager()
        createArrowNode()
        
        shootArrow()
        
        sceneView.frame = self.view.bounds
        self.sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        startingPoint = Date()
        self.focusNode.viewDelegate = sceneView
        sceneView.scene.rootNode.addChildNode(self.focusNode)
      
        
        
        
    }
    

    
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
        
        arrowScene.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0 )
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
            //let targetVector = SCNVector3Make( cameraNode.x - planeNode.x, cameraNode.y - planeNode.y, cameraNode.z - planeNode.z)

           
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
        arrowScene.physicsWorld.contactDelegate = self
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
        
        // Setup camera position from existing scene
        if let cameraNodeTmp = arrowScene.rootNode.childNode(withName: "camera", recursively: true){
            cameraNode = cameraNodeTmp
            sceneView.scene.rootNode.addChildNode(cameraNode)
            }
                
        if let lighting = arrowScene.rootNode.childNode(withName: "Lighting", recursively: true){
            sceneView.scene.rootNode.addChildNode(lighting)
            }

        return arrowNode
    }
    

    
    @IBAction func fireButtonPressed(_ sender: UIButton) {
        
        isFiring = true
                    
    }
    
    func configureArrowNode(_ arrowNode: SCNNode) { //set launch and trajectory of arrow
        // Configure physics
        sceneView.scene.rootNode.childNodes.filter({ $0.name == "Cone"}).forEach({$0.removeFromParentNode()})
        scene = SCNScene()
        scene?.physicsWorld.contactDelegate = self
        let physics = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape( geometry: arrowNode.geometry!, options: nil))
        physics.isAffectedByGravity = false
       

        physics.categoryBitMask = 0xFFFF
        physics.collisionBitMask = 0xFFFF
        physics.contactTestBitMask = 0xFFFF
        // Set appearance properties
        arrowNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        arrowNode.physicsBody = physics
        scene.rootNode.addChildNode(arrowNode)
        self.lastNode = arrowNode
        
        
        
    }
    
    @IBAction func fireButtonReleased(_ sender: UIButton) { //draw and release arrow
        isFiring = false

            if let arrowNode = createArrowNode() {
                configureArrowNode(arrowNode)
    
                // Add the arrow node to the scene
                sceneView.scene.rootNode.addChildNode(arrowNode)
                
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
                    
                    if let node = lastNode{
                        let moveValue:CGFloat = 0.0
                        let duration:TimeInterval = 5
                        var moveAction:SCNAction
                        let power : Double = (startingPoint!.timeIntervalSinceNow * -1)
                        moveAction = SCNAction.moveBy(x: CGFloat(arrowDirection.x) * 5.0 * -power, y: CGFloat(arrowDirection.y) * 5.0 * -power, z: Double(arrowDirection.z) * 5.0 * -power, duration: duration)
                        
                        node.runAction(moveAction)
                    }
                }
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
        
        
        // change the current object we are asking the participant to find
        
        scoreLabel.layer.add(animation, forKey: animationKey)
        scoreLabel.text = "You: \(self.score)"
        
        if(self.score>=5){
            // if here, End the game
            scoreLabel.layer.add(animation, forKey: animationKey)
            scoreLabel.text = "You Win!"
        }
        
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
// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCATransitionType(_ input: String) -> CATransitionType {
    return CATransitionType(rawValue: input)
}
