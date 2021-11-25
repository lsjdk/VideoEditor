//
//  Filter.swift
//  ParticleAdjuster
//
//  Created by chioacm on 2021/11/9.
//

import UIKit
import MetalKit
import Foundation

class PFilter : UIView {
    
   
   //
   let vertexs:[SIMD4<Float>] = [
      [-1.0 , -1.0 , 0.0 , 1.0 ], // 左下角 0
      [1.0  , -1.0 , 1.0 , 1.0 ], // 右下角 1
      [-1.0 ,  1.0 , 0.0 , 0.0 ], // 左上角 2
      [1.0  ,  1.0 , 1.0 , 0.0 ]  // 右上角 3
   ]
   //
   let indexs : [UInt16] = [
      0,1,2,
      1,2,3
   ]
   
   var mtkView : MTKView
   var device : MTLDevice
   var library : MTLLibrary
   var commondQueue : MTLCommandQueue

   var vertexBuffrt : MTLBuffer
   var indexsBuffrt : MTLBuffer

   var textureLoader : MTKTextureLoader
   var textureOptions : [MTKTextureLoader.Option : Any]

   var texture1 : MTLTexture?
   var texture2 : MTLTexture?
   

   var pipelineState : MTLRenderPipelineState

   var samplerState : MTLSamplerState
   
   //
   
   var saturation: Float = 1.0
   var contrast: Float = 0.0
   var brightness: Float = 1.0
   var gamma: Float = 1.0
   var palpha: Float = 1.0
   var add: Bool = false
   
   //
   typealias rennderBlock = (MTLTexture)->()
   var renderFinish: rennderBlock?
   
   //
   override init(frame: CGRect)  {
      // 直接获取系统默认使用的GPU即可
      self.device = MTLCreateSystemDefaultDevice()!
      
      self.commondQueue = self.device.makeCommandQueue()!
      
      self.mtkView = MTKView.init(frame: CGRect.zero, device: self.device)
      self.mtkView.framebufferOnly = false
      self.mtkView.device = self.device
      self.mtkView.enableSetNeedsDisplay = false
      self.mtkView.isPaused = true
      // self.mtkView.isOpaque = false
      
      
      
      // 顶点buffer
      self.vertexBuffrt = self.device.makeBuffer(bytes: vertexs, length: MemoryLayout<SIMD4<Float>>.stride * vertexs.count , options:[])!
      // 索引buffer
      self.indexsBuffrt = self.device.makeBuffer(bytes: indexs, length: MemoryLayout<UInt16>.stride * indexs.count, options:[])!
      // 纹理 loader
      self.textureLoader = MTKTextureLoader.init(device: self.device)
      self.textureOptions = [
         MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.topLeft,
         MTKTextureLoader.Option.SRGB: false,
         MTKTextureLoader.Option.generateMipmaps: NSNumber(booleanLiteral: false)
      ]


      // 构造 渲染管线 Pipeline
      // 1 先创建 descriptor
      let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
      // 2 添加参数
      // 获取 shader 的函数
      self.library = self.device.makeDefaultLibrary()!
      renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
      renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
      renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      // 3 生成 MTLRenderPipelineState
      self.pipelineState = try! self.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)


      // 构造 采样器
      let samplerDescriptor = MTLSamplerDescriptor()
      samplerDescriptor.sAddressMode = .clampToZero
      samplerDescriptor.tAddressMode = .clampToZero
      samplerDescriptor.maxAnisotropy = 8
      samplerDescriptor.mipFilter = .linear
      self.samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor)!
      
      
      super.init(frame: frame)
      self.mtkView.delegate = self
      self.mtkView.frame = self.bounds
      self.addSubview(self.mtkView)

   }
   
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
}


extension PFilter: MTKViewDelegate {

   func draw(in view: MTKView){
      
      /// 计算执行时间
      let startTime = CFAbsoluteTimeGetCurrent()

      guard
         let descriptor = self.mtkView.currentRenderPassDescriptor,
         let commandBuffer = self.commondQueue.makeCommandBuffer(),
         let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
      else { return }

      renderEncoder.setRenderPipelineState(self.pipelineState)
      
      
      renderEncoder.setFragmentBytes(&saturation,
                                            length: MemoryLayout<Float>.stride,
                                            index: 0)
      renderEncoder.setFragmentBytes(&contrast,
                                            length: MemoryLayout<Float>.stride,
                                            index: 1)
      renderEncoder.setFragmentBytes(&brightness,
                                            length: MemoryLayout<Float>.stride,
                                            index: 2)
      renderEncoder.setFragmentBytes(&gamma,
                                            length: MemoryLayout<Float>.stride,
                                            index: 3)
      renderEncoder.setFragmentBytes(&palpha,
                                            length: MemoryLayout<Float>.stride,
                                            index: 4)
      renderEncoder.setFragmentBytes(&add,
                                            length: MemoryLayout<Bool>.stride,
                                            index: 5)
      
      renderEncoder.setFragmentSamplerState(self.samplerState, index: 0)

      //
      renderEncoder.setVertexBuffer(self.vertexBuffrt, offset: 0, index: 0)
      
      //
      renderEncoder.setFragmentTextures([self.texture1,self.texture2], range: 0..<2)
      //
      renderEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: indexs.count,
                                          indexType: .uint16,
                                          indexBuffer: self.indexsBuffrt,
                                          indexBufferOffset: 0)
      //
      renderEncoder.endEncoding()
      //
      guard
         let drawable = view.currentDrawable
      else { return }
      commandBuffer.present(drawable)

      ///
      commandBuffer.addCompletedHandler { (commanbuffer) in
//         let ciImageOptions = [
//            CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB()
//         ]
//         let img = CIImage(
//            mtlTexture: drawable.texture,
//            options: ciImageOptions)!
//            .oriented(CGImagePropertyOrientation.downMirrored)
         
         self.renderFinish!(drawable.texture)
                  
         debugPrint("渲染时长ms:", (CFAbsoluteTimeGetCurrent() - startTime)*1000)
      }
      commandBuffer.commit()
      
      
      
      
   }
   //
   func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
      
   }
}



extension PFilter {
    
    func towImage(cgImage1 : CGImage , cgImage2 : CGImage) {
        self.texture1  = try! textureLoader.newTexture(cgImage: cgImage1, options: self.textureOptions)
        //
        self.texture2  = try! textureLoader.newTexture(cgImage: cgImage2, options: self.textureOptions)
        
    }
}
