//
//  Chameleon.swift
//  InteractiveContent
//
//  Created by mac126 on 2018/3/27.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit

class Chameleon: SCNScene {

    // Special nodes used to control animations of the model
    private let contentRootNode = SCNNode()
    private var geometryRoot: SCNNode!
    private var skin: SCNMaterial!
    
    // Animations
    private var idleAnimation: SCNAnimation?
    private var turnLeftAnimation: SCNAnimation?
    private var turnRightAnimation: SCNAnimation?
    
    // State variables 状态变量
    private var modelLoaded: Bool = false
    private var chameleonIsTurning: Bool = false
    
    // MARK: - Initialization and Loading
    
    override init() {
        super.init()
        
        // Load the environment map
        self.lightingEnvironment.contents = UIImage(named: "art.scnassets/environment_blur.exr")!
        
        // Load the chameleon
        loadModel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else {
            return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        self.rootNode.addChildNode(contentRootNode)
        contentRootNode.addChildNode(wrapperNode)
        hide()
        
        setupSpecialNodes()

        setupShader()
        preloadAnimations()
        
        
        modelLoaded = true
    }
    
    // MARK: - Public API
    
    func show() {
        contentRootNode.isHidden = false
    }
    
    func hide() {
        contentRootNode.isHidden = true
    }
    
    func isVisible() -> Bool {
        return !contentRootNode.isHidden
    }
    
    func setTransform(_ transform: simd_float4x4) {
        contentRootNode.simdTransform = transform
    }
    
    // MARK: - Turn left/right and idle animations
    
    private func preloadAnimations() {
        idleAnimation = SCNAnimation.fromFile(named: "anim_idle", inDirectory: "art.scnassets")
        idleAnimation?.repeatCount = -1
        
        turnLeftAnimation = SCNAnimation.fromFile(named: "anim_turnleft", inDirectory: "art.scnassets")
        turnLeftAnimation?.repeatCount = 1
        turnLeftAnimation?.blendInDuration = 0.3
        turnLeftAnimation?.blendOutDuration = 0.3
        
        turnRightAnimation = SCNAnimation.fromFile(named: "anim_turnright", inDirectory: "art.scnassets")
        turnRightAnimation?.repeatCount = 1
        turnRightAnimation?.blendInDuration = 0.3
        turnRightAnimation?.blendOutDuration = 0.3
        
        // Start playing idle animation.
        if let anim = idleAnimation {
            contentRootNode.childNodes[0].addAnimation(anim, forKey: anim.keyPath)
        }
    }
    
    private func playTurnAnimation(_ animation: SCNAnimation) {
        var rotationAngle: Float = 0
        if animation == turnLeftAnimation {
            rotationAngle = Float.pi / 4
        } else if animation == turnRightAnimation {
            rotationAngle = -Float.pi / 4
        }
        
        let modelBaseNode = contentRootNode.childNodes[0]
        modelBaseNode.addAnimation(animation, forKey: animation.keyPath)
        
        chameleonIsTurning = true
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        SCNTransaction.animationDuration = animation.duration
        modelBaseNode.transform = SCNMatrix4Mult(modelBaseNode.presentation.transform, SCNMatrix4MakeRotation(rotationAngle, 0, 1, 0))
        SCNTransaction.completionBlock = {
            self.chameleonIsTurning = false
        }
        SCNTransaction.commit()
    }
    
    
    
}

// MARK: - Helper functions

extension Chameleon {
    
    private func setupSpecialNodes() {
        // Retrieve nodes we need to reference for animations.
        geometryRoot = self.rootNode.childNode(withName: "Chameleon", recursively: true)
       
        skin = geometryRoot.geometry?.materials.first
        
        // Fix materials
        geometryRoot.geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometryRoot.geometry?.firstMaterial?.roughness.contents = "art.scnassets/textures/chameleon_ROUGHNESS.png"
        let shadowPlane = self.rootNode.childNode(withName: "Shadow", recursively: true)
        shadowPlane?.castsShadow = false

    }
    
    private func setupShader() {
        guard let path = Bundle.main.path(forResource: "skin", ofType: "shaderModifier", inDirectory: "art.scnassets"),
            let shader = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else {
                return
        }
        
        skin.shaderModifiers = [SCNShaderModifierEntryPoint.surface: shader]
        
        skin.setValue(Double(0), forKey: "blendFactor")
        skin.setValue(NSValue(scnVector3: SCNVector3Zero), forKey: "skinColorFromEnvironment")
        
        let sparseTexture = SCNMaterialProperty(contents: UIImage(named: "art.scnassets/textures/chameleon_DIFFUSE_BASE.png")!)
        skin.setValue(sparseTexture, forKey: "sparseTexture")
    }
}
