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
