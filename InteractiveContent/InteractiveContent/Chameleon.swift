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

    // 特殊节点控制模型动画
    /// 根节点
    private let contentRootNode = SCNNode()
    private var geometryRoot: SCNNode!
    private var head: SCNNode!
    private var leftEye: SCNNode!
    private var rightEye: SCNNode!
    /// 下巴
    private var jaw: SCNNode!
    /// 舌尖
    private var tongueTip: SCNNode!
    private var focusOfTheHead: SCNNode!
    private var focusOfLeftEye: SCNNode!
    private var focusOfRightEye: SCNNode!
    /// 舌头休息
    private var tongueRestPositionNode: SCNNode!
    /// 皮肤
    private var skin: SCNMaterial!
    
    // Animations
    private var idleAnimation: SCNAnimation?
    private var turnLeftAnimation: SCNAnimation?
    private var turnRightAnimation: SCNAnimation?
    
    // 状态变量
    private var modelLoaded: Bool = false
    private var headIsMoving: Bool = false
    private var chameleonIsTurning: Bool = false
    
    /// ??
    private var focusNodeBasePosition = simd_float3(0, 0.1, 0.25)
    private var leftEyeTargetOffset = simd_float3()
    private var rightEyeTargetOffset = simd_float3()
    /// 现在舌头位置
    private var currentTonguePosition = simd_float3()
    /// 相应吐舌头因子
    private var relativeTongueStickOutFactor: Float = 0
    /// 准备吐舌头计数器
    private var readyToShootCounter: Int = 0
    /// 触发左转计数器
    private var triggerTurnLeftCounter: Int = 0
    /// 触发右转计数器
    private var triggerTurnRightCounter: Int = 0
    /// 最后的相对位置
    private var lastRelativePosition: RelativeCameraPositionToHead = .tooHighOrLow
    private var distance: Float = Float.greatestFiniteMagnitude
    private var didEnterTargetLockDistance = false
    /// 嘴部动画状态
    private var mounthAnimationState: MouthAnimationState = .mouthClosed
    
    /// 更改颜色计时器
    private var changeColorTimer: Timer?
    private var lastColorFromEnvironment = SCNVector3(130.0 / 255.0, 196.0 / 255.0, 174.0 / 255.0)
    
    // Enums
    /// 相机位置相对头部的状态
    private enum RelativeCameraPositionToHead {
        case withinFieldOfView(Distance)
        case needToTurnLeft
        case needToTurnRight
        case tooHighOrLow
        
        var rawValue: Int {
            switch self {
            case .withinFieldOfView(_): return 0
            case .needToTurnLeft: return 1
            case .needToTurnRight: return 2
            case .tooHighOrLow : return 3
            }
        }
    }
    
    /// 距离
    private enum Distance {
        case outsideTargetLockDistance  // 超出目标锁定距离
        case withinTargetLockDistance   // 进入目标锁定距离
        case withinShootTongueDistance  // 进入发射舌头距离
    }
    
    /// 嘴部动画状态
    private enum MouthAnimationState {
        case mouthClosed
        case mouthMoving
        case shootingTongue     // 发射舌头
        case pullingBackTongue  // 收回舌头
    }
    
    // MARK: - Initialization and Loading
    
    override init() {
        super.init()
        
        // 加载环境地图
        self.lightingEnvironment.contents = UIImage(named: "art.scnassets/environment_blur.exr")!
        
        // 加载变色龙
        loadModel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 加载模型
    private func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else { return  }
        
        // 包装节点
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        self.rootNode.addChildNode(contentRootNode)
        contentRootNode.addChildNode(wrapperNode)
        // 隐藏
        hide()
        
        // 设置节点
        setupSpecialNodes()
        // 设置约束
        setupConstraints()
        // TODO: 设置着色器 ？？？？？
        setupShader()
        // 加载动画
        preloadAnimations()
        
        modelLoaded = true
    }
    
    // MARK: - public api
    func hide() {
        contentRootNode.isHidden = true
        // 重置状态
        resetState()
    }
    
    func show() {
        contentRootNode.isHidden = false
    }
    
    // MARK: - 转向和初始动画
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
        
        // 开始初始动画
        if let anim = idleAnimation {
            contentRootNode.childNodes[0].addAnimation(anim, forKey: anim.keyPath)
        }
        
        tongueTip.removeAllAnimations()
        leftEye.removeAllAnimations()
        rightEye.removeAllAnimations()
        chameleonIsTurning = false
        headIsMoving = false
    }
}

// MARK: - Helper functions

extension Chameleon {
    
    /// 弧度
    private func rad(_ deg: Float) -> Float {
        return deg * Float.pi / 180
    }
    
    
    
    /// 设置节点
    private func setupSpecialNodes() {
        geometryRoot = self.rootNode.childNode(withName: "Chameleon", recursively: true)
        head = self.rootNode.childNode(withName: "Neck02", recursively: true)
        leftEye = self.rootNode.childNode(withName: "Eye_L", recursively: true)
        rightEye = self.rootNode.childNode(withName: "Eye_R", recursively: true)
        jaw = self.rootNode.childNode(withName: "Jaw", recursively: true)
        tongueTip = self.rootNode.childNode(withName: "TongueTip_Target", recursively: true)
        
        skin = geometryRoot.geometry?.materials.first
        
        // fix materials
        geometryRoot.geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometryRoot.geometry?.firstMaterial?.roughness.contents = "art.scnassets/textures/chameleon_ROUGHNESS.png"
        let shadowPlane = self.rootNode.childNode(withName: "Shadow", recursively: true)
        // 确认是否节点是否呈现阴影贴图，默认为yes
        shadowPlane?.castsShadow = false
        
        // 设置视位置节点
        focusOfTheHead.simdPosition = focusNodeBasePosition
        focusOfLeftEye.simdPosition = focusNodeBasePosition
        focusOfRightEye.simdPosition = focusNodeBasePosition
        geometryRoot.addChildNode(focusOfTheHead)
        geometryRoot.addChildNode(focusOfLeftEye)
        geometryRoot.addChildNode(focusOfRightEye)
    }
    
    /// 设置约束
    private func setupConstraints() {
        // 头部运动约束
        let headConstraint = SCNLookAtConstraint(target: focusOfTheHead)
        // 是否允许约束旋转
        headConstraint.isGimbalLockEnabled = true
        head.constraints = [headConstraint]
        
        // 眼部运动约束
        let leftEyeLookAtConstraint = SCNLookAtConstraint(target: focusOfLeftEye)
        leftEyeLookAtConstraint.isGimbalLockEnabled = true
        
        let rightEyeLookAtConstraint = SCNLookAtConstraint(target: focusOfRightEye)
        rightEyeLookAtConstraint.isGimbalLockEnabled = true
        
        // 眼部旋转约束
        let eyeRotationConstraint = SCNTransformConstraint(inWorldSpace: false) { (node, transform) -> SCNMatrix4 in
            
            var eulerX = node.presentation.eulerAngles.x
            var eulerY = node.presentation.eulerAngles.y
            
            // x
            if eulerX < self.rad(-20) { eulerX = self.rad(-20) }
            if eulerX > self.rad(20) { eulerX = self.rad(20) }
            // 绕y轴 旋转限制在5 - 150
            if node.name == "Eye_R" {
                if eulerY < self.rad(-150) { eulerY = self.rad(-150) }
                if eulerY > self.rad(-5) { eulerY = self.rad(-5) }
            } else {
                if eulerY > self.rad(150) { eulerY = self.rad(150)}
                if eulerY < self.rad(5) { eulerY = self.rad(5)}
            }
            
            let tempNode = SCNNode()
            tempNode.transform = node.presentation.transform
            tempNode.eulerAngles = SCNVector3(x: eulerX, y: eulerY, z: 0)
            return tempNode.transform
            
        }
        
        leftEye.constraints = [leftEyeLookAtConstraint, eyeRotationConstraint]
        rightEye.constraints = [rightEyeLookAtConstraint, eyeRotationConstraint]

        // 舌头位置
        tongueTip.parent?.addChildNode(tongueRestPositionNode)
        tongueRestPositionNode.transform = tongueTip.transform
        currentTonguePosition = tongueTip.simdPosition
    }
    
    /// 重置状态
    private func resetState() {
        relativeTongueStickOutFactor = 0
        
        mounthAnimationState = .mouthClosed
        
        readyToShootCounter = 0
        triggerTurnLeftCounter = 0
        triggerTurnRightCounter = 0
        
        // 清空计时器
        if changeColorTimer != nil {
            changeColorTimer?.invalidate()
            changeColorTimer = nil
        }
        
    }
    
    /// 设置着色器
    private func setupShader() {
        
    }
}

