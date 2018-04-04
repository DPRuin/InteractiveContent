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
//        startNewSession()
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
            // chameleon.setTransform(hit.worldTransform)
            // chameleon.reactToPositionChange(in: sceneView)
        }
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        
    }
    
}

extension UIViewController: ARSCNViewDelegate {
    
}



