//
//  Extensions.swift
//  InteractiveContent
//
//  Created by mac126 on 2018/3/27.
//  Copyright © 2018年 mac126. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

extension ARSCNView {
    
    /// 平均颜色从环境中, 返回颜色向量
    func averageColorFromEnvironment(at screenPos: SCNVector3) -> SCNVector3 {
        var colorVector = SCNVector3()
        // 1.获取没有内容的scene的截图
        scene.rootNode.isHidden = true
        // 屏幕截图 snapshot()是线程安全的可以随时调用
        let screenshot: UIImage = snapshot()
        scene.rootNode.isHidden = false
        
        // 2.从屏幕的位置使用一小片
        let scale = UIScreen.main.scale
        let patchSize: CGFloat = 100 * scale
        
        let screenPoint = CGPoint(x: (CGFloat(screenPos.x) - patchSize / 2) * scale,
                                  y: (CGFloat(screenPos.y) - patchSize / 2) * scale)
        let cropRect = CGRect(origin: screenPoint, size: CGSize(width: patchSize, height: patchSize))
        // 裁切
        if let cropedCGImage = screenshot.cgImage?.cropping(to: cropRect) {
            let image = UIImage(cgImage: cropedCGImage)
            if let avgcolor = image.averageColor() {
                colorVector = SCNVector3(avgcolor.red, avgcolor.green, avgcolor.blue)
            }
        }
        return colorVector
    }
}

extension SCNAnimation {
    
    /// 获取模型动画
    static func fromFile(named name: String, inDirectory: String) -> SCNAnimation? {
        let animScene = SCNScene(named: name, inDirectory: inDirectory)
        var animation: SCNAnimation?
        
        animScene?.rootNode.enumerateChildNodes({ (child, stop) in
            if !child.animationKeys.isEmpty { // 节点动画key不为空
                let player = child.animationPlayer(forKey: child.animationKeys[0])
                animation = player?.animation
                
                // 停止
                stop.initialize(to: true)
            }
        })
        // ？？ 关键路径
        animation?.keyPath = name
        
        return animation
        
    }
}

extension UIImage {
    
    /// 平均颜色
    func averageColor() -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        
        /*
         CIFilter是CoreImage核心图像的过滤器
         */
        if let cgImage = self.cgImage, let averageFilter = CIFilter(name: "CIAverageFilter") {
            let ciImage = CIImage(cgImage: cgImage)
            // 大小
            let extent = ciImage.extent
            // 用于CoreImage核心图像过滤器参数
            let ciExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            // 输入图像
            averageFilter.setValue(ciImage, forKey: kCIInputImageKey)
            // 输入范围
            averageFilter.setValue(ciExtent, forKey: kCIInputExtentKey)
            
            // 过滤器输出图像
            if let outputImage = averageFilter.outputImage {
                // 核心图形渲染和分析的上下文
                let context = CIContext(options: nil)
                // 创建默认值为0，数量为4的数组
                var bitmap = [UInt8](repeatElement(0, count: 4))
                // 交出位图
                context.render(outputImage,
                               toBitmap: &bitmap,
                               rowBytes: 4,
                               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                               format: kCIFormatRGBA8,
                               colorSpace: CGColorSpaceCreateDeviceRGB())
                
                return (red: CGFloat(bitmap[0]) / 255.0,
                    green: CGFloat(bitmap[1]) / 255.0,
                    blue: CGFloat(bitmap[2]) / 255.0)
            }
        }
        return nil
    }
}
