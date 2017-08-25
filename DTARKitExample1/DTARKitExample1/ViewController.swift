//
//  ViewController.swift
//  DTARKitExample1
//
//  Created by Dima Tsurkan on 8/25/17.
//  Copyright © 2017 Dima Tsurkan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

private enum GameState {
    case placing
    case shootting
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Constants
    private static let logoMaxCount = 3
    private static let cameraToLogoSpace: Float = -1
    
    // MARK: - IBOutlets
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var scoreLabel: UILabel!
    @IBOutlet private weak var prizelImageView: UIImageView!
    
    // MARK: - Properties
    fileprivate var state: GameState = .placing {
        didSet {
            prizelImageView.isHidden = state == .placing
        }
    }
    fileprivate var logoCount = 0 {
        didSet {
            DispatchQueue.main.async {
//                self.scoreLabel.text = "\(self.logoCount)"
            }
        }
    }
    fileprivate var gameSeconds = 0
    fileprivate var gameTimer: Timer?
    
    
     // MARK: - ViewController life cycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        logoCount = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARConfiguration.isSupported ? ARWorldTrackingConfigurationARWorldTrackingConfiguration()
            : ARConfigurationARConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        stopGame()
    }
    
    @objc private func tapAction() {
        switch state {
        case .placing:
            addLogo()
        case .shootting:
            shoot()
        }
    }
    
    private func addLogo() {
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        let logo = Logo()
        sceneView.scene.rootNode.addChildNode(logo)
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1
        logo.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        logoCount += 1
        if logoCount == ViewController.logoMaxCount {
            startGame()
        }
    }
    
    private func shoot() {
        let arBullet = ARBullet()
        
        let (direction, position) = cameraVector
        arBullet.position = position
        arBullet.physicsBody?.applyForce(direction, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(arBullet)
    }
}

// MARK: - Game logic
extension ViewController {
    
    fileprivate func startGame() {
        state = .shootting
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.gameSeconds += 1
            DispatchQueue.main.async {
                self?.configureTimeLabel()
            }
        })
    }
    
    fileprivate func stopGame() {
        state = .placing
        
        gameTimer?.invalidate()
        gameTimer = nil
        
        gameSeconds = 0
        logoCount = 0
        
        configureTimeLabel()
    }
    
    fileprivate func configureTimeLabel() {
        timeLabel.isHidden = self.gameSeconds == 0
        
        let seconds = self.gameSeconds % 60
        let minutes = (self.gameSeconds / 60) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
}

// MARK: - Utils
extension ViewController {
    
    fileprivate var cameraVector: (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            return (dir, pos)
        }
        return (SCNVector3(0, 0, 0), SCNVector3(0, 0, 0))
    }
    
}

extension ViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let nodeABitMask = contact.nodeA.physicsBody?.categoryBitMask,
            let nodeBBitMask = contact.nodeB.physicsBody?.categoryBitMask,
            nodeABitMask & nodeBBitMask == CollisionCategory.logos.rawValue & CollisionCategory.arBullets.rawValue else {
                return
        }
        
        contact.nodeB.removeFromParentNode()
        logoCount -= 1
        
        if logoCount == 0 {
            DispatchQueue.main.async {
                self.stopGame()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            contact.nodeA.removeFromParentNode()
        })
    }
    
}
