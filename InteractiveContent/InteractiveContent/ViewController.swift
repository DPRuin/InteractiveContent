//
//  ViewController.swift
//  InteractiveContent
//
//  Created by mac126 on 2018/3/27.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    /// 模糊效果
    @IBOutlet weak var toast: UIVisualEffectView!
    
    /// 提示
    @IBOutlet weak var label: UILabel!
    
    var chameleon = Chameleon()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = chameleon
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("设备不支持ARWorldTrackingConfiguration")
        }
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start a new session
        startNewSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func startNewSession() {
        // hide toast
        self.toast.alpha = 0
        self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        
        chameleon.hide()
        
        // Create a session configuration with horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    // MARK: - 手势
    
    @IBAction func didTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        
        // When tapped on the object, call the object's method to react on it
        let sceneHitTestResult = sceneView.hitTest(location, options: nil)
        if !sceneHitTestResult.isEmpty {

            // chameleon.reactToTap(in: sceneView)
            return
        }
        
        // When tapped on a plane, reposition the content
        let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
        if !arHitTestResult.isEmpty {
            let hit = arHitTestResult.first!
            chameleon.setTransform(hit.worldTransform)
            // chameleon.reactToPositionChange(in: sceneView)
        }
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        
    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if chameleon.isVisible() { return }
        
        // Unhide the content and position it on the detected plane
        if anchor is ARPlaneAnchor {
            chameleon.setTransform(anchor.transform)
            chameleon.show()
            // chameleon.reactToInitialPlacement(in: sceneView)
            
            DispatchQueue.main.async {
                self.hideToast()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // chameleon.reactToRendering(in: sceneView)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyConstraintsAtTime time: TimeInterval) {
        // chameleon.reactToDidApplyConstraints(in: sceneView)
    }
}

extension ViewController: ARSessionObserver {
    
    func sessionWasInterrupted(_ session: ARSession) {
        showToast("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        startNewSession()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        showToast("Session failed: \(error.localizedDescription)")
        startNewSession()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String? = nil
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking not available"
        case .limited(.initializing):
            message = "Initializing AR session"
        case .limited(.excessiveMotion):
            message = "Too much motion"
        case .limited(.insufficientFeatures):
            message = "Not enough surface details"
        case .normal:
            if !chameleon.isVisible() {
                message = "Move to find a horizontal surface"
            }
        default:
            // We are only concerned with the tracking states above.
            message = "Camera changed tracking state"
        }
        
        message != nil ? showToast(message!) : hideToast()
    }
}


// MARK: - 提示
extension ViewController {
    
    func showToast(_ text: String) {
        label.text = text
        
        guard toast.alpha == 0 else {
            return
        }
        
        toast.layer.masksToBounds = true
        toast.layer.cornerRadius = 7.5
        
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 1
            self.toast.frame = self.toast.frame.insetBy(dx: -5, dy: -5)
        })
        
    }
    
    func hideToast() {
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 0
            self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        })
    }
}
