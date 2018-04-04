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
        
    }
    
    // MARK: - public api
    func hide() {
        contentRootNode.isHidden = true
    }
    
    func show() {
        contentRootNode.isHidden = false
    }
    
    // MARK: - 转向和初始动画
    
}

// MARK: - Helper functions

extension Chameleon {
    
    /// 重置状态
    private func resetState() {
        
    }
}

