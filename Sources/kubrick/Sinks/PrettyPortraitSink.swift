import Foundation

#if os(iOS)
    #if arch(arm) || arch(arm64)
    import CoreVideo
    import CoreMedia
    import VideoToolbox
    import MetalKit
    import Metal
    import MetalPerformanceShaders
    
    public enum PrettyPortraitError: Error {
        case pipelineSetupFailed
        case shaderNotFound(name: String)
    }

    public class PrettyPortrait: Sink<Sample>, NextSinkProtocol {
        
        /// Cache pools for metal textures and cv pixel buffers
        var textureCache: CVMetalTextureCache?
        var pixelBufferPool: CVPixelBufferPool?
        
        /// Metal device, command queue, and kernel function library
        var device: MTLDevice
        var commandQueue: MTLCommandQueue
        var library: MTLLibrary
        
        ///// Functions used for the effect
        var passthroughFunction: MTLFunction
        var passthroughPiplineState: MTLComputePipelineState
        
        var veritcalCenterFunction: MTLFunction
        var verticalCenterPiplineState: MTLComputePipelineState
        
        var horizontalCenterFunction: MTLFunction
        var horizontalCenterPipelineState: MTLComputePipelineState
        
        var flipFunction: MTLFunction
        var flipPipelineState: MTLComputePipelineState
        
        //// Textures used to modify the images
        var backgroundTexture: MTLTexture?
        var foregroundTextureClip: MTLTexture?
        var foregroundTexture: MTLTexture?
        public var presentedTexture: MTLTexture?
        
        //// Use this when we need to reconfigure textures
        public var configured: Bool = false
        
        //// Performance shaders for some of the fancier effects
        let blur: MPSImageGaussianBlur
        var scale: MPSImageLanczosScale
        var tranpose: MPSImageTranspose
        
        /// Queue used for building new samples after they've been processed by the CPU
        var samples                     = ThreadSafeArray<Sample>()
        var sampleBuilderQ              = DispatchQueue(label: "sample.builder.q")
        
        /// The sinks
        public var nextSinks: [Sink<Sample>]   = []
        
        fileprivate var semaphore = DispatchSemaphore(value: 1)
        
        let copyAllocator: MPSCopyAllocator =
        {
            (kernel: MPSKernel, buffer: MTLCommandBuffer, sourceTexture: MTLTexture) -> MTLTexture in
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat,
                                                                      width: sourceTexture.width,
                                                                      height: sourceTexture.height,
                                                                      mipmapped: false)
            let targetTexture: MTLTexture = buffer.device.makeTexture(descriptor: descriptor)!
            return targetTexture
        }
        
        
        public init(device: MTLDevice) throws {
            self.device   = device
            
            self.blur     = MPSImageGaussianBlur(device: device, sigma: 55.0)
            self.scale    = MPSImageLanczosScale(device: device)
            self.tranpose = MPSImageTranspose(device: device)
            
            if let cmdQ = device.makeCommandQueue() { self.commandQueue = cmdQ }
            else { throw PrettyPortraitError.pipelineSetupFailed }
            
            if let library = device.makeDefaultLibrary() { self.library = library }
            else { throw PrettyPortraitError.pipelineSetupFailed }
            
            if let function = library.makeFunction(name: "passthrough") { self.passthroughFunction = function }
            else { throw PrettyPortraitError.shaderNotFound(name: "passthrough")}
            self.passthroughPiplineState = try device.makeComputePipelineState(function: self.passthroughFunction)
            
            if let function = library.makeFunction(name: "verticalCenter") { self.veritcalCenterFunction = function }
            else { throw PrettyPortraitError.shaderNotFound(name: "verticalCenter")}
            self.verticalCenterPiplineState = try device.makeComputePipelineState(function: self.veritcalCenterFunction)
            
            if let function = library.makeFunction(name: "horizontalCenter") { self.horizontalCenterFunction = function }
            else { throw PrettyPortraitError.shaderNotFound(name: "horizontalCenter")}
            self.horizontalCenterPipelineState = try device.makeComputePipelineState(function: self.horizontalCenterFunction)
            
            if let function = library.makeFunction(name: "flip") { self.flipFunction = function }
            else { throw PrettyPortraitError.shaderNotFound(name: "flip")}
            self.flipPipelineState = try device.makeComputePipelineState(function: self.flipFunction)
            
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
            
            super.init()
        }
        
        public override func push(input: Sample) {
            if !self.configured { self.configureTextures(with: input) }
            let sample = input as! CMSampleBuffer
            if let textureA = texture(sampleBuffer: sample, textureCache: textureCache) {
                if let textureB = texture(sampleBuffer: sample, textureCache: textureCache) {
                    self.samples.append(input)
                    self.encode(background: textureA, foreground: textureB)
                }
            }
        }
        
        func configureTextures(with sample: Sample) {
            var width: UInt32   = 0
            var height: UInt32  = 0
            if let desc = sample.format?.details as? VideoFormatDescription {
                width               = desc.dimensions.width
                height              = desc.dimensions.height
            }
            
            if width < height {
                let aspectWidth = (width/16)*9
                self.backgroundTexture      = self.texture(device: device, width: height, height: width)
                self.foregroundTextureClip  = self.texture(device: device, width: height, height: width)
                self.foregroundTexture      = self.texture(device: device, width: aspectWidth, height: width)
            } else {
                self.backgroundTexture      = self.texture(device: device, width: width/2, height: height/2)
                self.foregroundTextureClip  = self.texture(device: device, width: width, height: height)
                self.foregroundTexture      = self.texture(device: device, width: width, height: height)
            }
            
            if let fmt = sample.format {
                let format = fmt as! CMFormatDescription
                let output = allocateOutputBufferPool(with: format, outputRetainedBufferCountHint: 2)
                self.pixelBufferPool = output.0
            }
            
            self.configured        = true
        }
        
        func encode(background: MTLTexture, foreground: MTLTexture) {
            if let cmdBuffer = self.commandQueue.makeCommandBuffer(),
                let pixelBufferPool = self.pixelBufferPool
            {
                let width  = background.width
                let height = background.height
                
                var computedPixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &computedPixelBuffer)
                guard let endPixelBuffer = computedPixelBuffer else { return }
                
                _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                
                let computedTexture = texture(pixelBuffer: endPixelBuffer, textureFormat: .bgra8Unorm)
                
                cmdBuffer.addCompletedHandler { _ in
                    self.presentedTexture = computedTexture
                    if let sample = self.samples.first {
                        if let pixelBuffer = computedPixelBuffer {
                            self.buildNewSample(using: pixelBuffer, and: sample)
                            self.samples.removeFirst(n: 1)
                        }
                    }
                    self.semaphore.signal()
                }
                
                if height > width {
                    self.scale(with: cmdBuffer, src: background, dst: self.backgroundTexture)
                    self.blur(with: cmdBuffer, src: self.backgroundTexture)
                    self.scale(with: cmdBuffer, src: self.backgroundTexture, dst: computedTexture!)
                    
                    self.scale(with: cmdBuffer, src: foreground, dst: self.foregroundTextureClip)
                    self.scale(with: cmdBuffer, src: self.foregroundTextureClip, dst: self.foregroundTexture)
                    self.horizontalCenter(with: cmdBuffer, src: self.foregroundTexture, dst: computedTexture!)
                    
                } else {
                    self.scale(with: cmdBuffer, src: foreground, dst: computedTexture!)
                }
                
                cmdBuffer.commit()
            }
        }
        
        func buildNewSample(using pixelBuffer: CVPixelBuffer, and sample: Sample) {
            let duration    = CMTimeMake(sample.duration.numerator, sample.duration.denominator)
            let pts         = CMTimeMake(sample.pts.numerator, sample.pts.denominator)
            var timingInfo  = CMSampleTimingInfo(duration: duration, presentationTimeStamp: pts, decodeTimeStamp: kCMTimeInvalid)
            
            var videoInfo: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &videoInfo)
            if let videoFormat = videoInfo {
                var newSample: CMSampleBuffer?
                CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, nil, nil, videoFormat, &timingInfo, &newSample)
                if let newSample = newSample {
                    for next in self.nextSinks { next.push(input: newSample) }
                }
            }
        }
        
        func texture(device: MTLDevice, width: UInt32, height: UInt32) -> MTLTexture {
            let descriptor         = MTLTextureDescriptor()
            descriptor.width       = Int(width)
            descriptor.height      = Int(height)
            descriptor.pixelFormat = .bgra8Unorm
            descriptor.usage       = [.shaderWrite, .shaderRead]
            return device.makeTexture(descriptor : descriptor)!
        }
        
        func blur(with buffer: MTLCommandBuffer, src: MTLTexture?) {
            guard var srcText = src else { return }
            self.blur.encode(commandBuffer: buffer,
                             inPlaceTexture: &srcText,
                             fallbackCopyAllocator: copyAllocator)
        }
        
        func scale(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            guard let srcText = src, let dstText = dst else { return }
            self.scale.encode(commandBuffer: buffer,
                              sourceTexture: srcText,
                              destinationTexture: dstText)
        }
        
        func tranpose(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            guard let src = src, let dst = dst else { return }
            self.tranpose.encode(commandBuffer: buffer, sourceTexture: src, destinationTexture: dst)
        }
        
        func passthrough(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            self.encodeCompute(name: "PassThrough", state: self.passthroughPiplineState, buffer: buffer, src: src, dst: dst)
        }
        
        func verticalCenter(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            self.encodeCompute(name: "VerticalCenter", state: self.verticalCenterPiplineState, buffer: buffer, src: src, dst: dst)
        }
        
        func horizontalCenter(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            self.encodeCompute(name: "HorizontalCenter", state: self.horizontalCenterPipelineState, buffer: buffer, src: src, dst: dst)
        }
        
        func flip(with buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            self.encodeCompute(name: "Flip", state: self.flipPipelineState, buffer: buffer, src: src, dst: dst)
        }
        
        func encodeCompute(name: String, state: MTLComputePipelineState, buffer: MTLCommandBuffer, src: MTLTexture?, dst: MTLTexture?) {
            guard let src = src, let dst = dst else { return }
            guard let encoder = buffer.makeComputeCommandEncoder() else { return }
            
            encoder.setComputePipelineState(state)
            encoder.pushDebugGroup(name)
            
            encoder.setTexture(src, index: 0)
            encoder.setTexture(dst, index: 1)
            
            let groupSize = MTLSize(width: 16, height: 16, depth: 1)
            let numGroups = MTLSize(width: (src.width + groupSize.width - 1 ) / groupSize.width,
                                    height: (src.height + groupSize.height - 1) / groupSize.height,
                                    depth: 1)
            
            encoder.dispatchThreadgroups(numGroups, threadsPerThreadgroup: groupSize)
            encoder.endEncoding()
        }
        
        private func texture(sampleBuffer: CMSampleBuffer?,
                             textureCache: CVMetalTextureCache?,
                             planeIndex: Int = 0,
                             pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture?
        {
            guard let sampleBuffer = sampleBuffer,
                let textureCache = textureCache,
                let imageBuffer  = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            
            let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
            let width    = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetWidth(imageBuffer)
            let height   = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetHeight(imageBuffer)
            
            var imageTexture: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                      textureCache,
                                                      imageBuffer,
                                                      nil,
                                                      pixelFormat,
                                                      width,
                                                      height,
                                                      planeIndex,
                                                      &imageTexture)
            
            if let imgTexture = imageTexture { return CVMetalTextureGetTexture(imgTexture) }
            return nil
        }
        
        private func texture(pixelBuffer: CVPixelBuffer, textureFormat: MTLPixelFormat) -> MTLTexture? {
            guard let textureCache = textureCache else { return nil }
            
            let width  = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            // Create a Metal texture from the image buffer
            var cvTextureOut: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                      textureCache,
                                                      pixelBuffer,
                                                      nil,
                                                      textureFormat,
                                                      width,
                                                      height,
                                                      0,
                                                      &cvTextureOut)
            
            guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
                CVMetalTextureCacheFlush(textureCache, 0)
                return nil
            }
            
            return texture
        }
        
    }
    
    func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription,
                                  outputRetainedBufferCountHint: Int) ->(
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?) {
            
            let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
            if inputMediaSubType != kCVPixelFormatType_32BGRA {
                assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
                return (nil, nil, nil)
            }
            
            let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
            var pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
                kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
                kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            
            if inputDimensions.width < inputDimensions.height {
                pixelBufferAttributes[kCVPixelBufferWidthKey as String] = Int(inputDimensions.height)
                pixelBufferAttributes[kCVPixelBufferHeightKey as String] = Int(inputDimensions.width)
            }
            
            // Get pixel buffer attributes and color space from the input format description
            var cgColorSpace = CGColorSpaceCreateDeviceRGB()
            if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
                let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]
                
                if let colorPrimaries = colorPrimaries {
                    var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]
                    
                    if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                        colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                    }
                    
                    if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                        colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                    }
                    
                    pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
                }
                
                if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                    cgColorSpace = cvColorspace as! CGColorSpace
                } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                    cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
                }
            }
            
            // Create a pixel buffer pool with the same pixel attributes as the input format description
            let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
            var cvPixelBufferPool: CVPixelBufferPool?
            CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
            guard let pixelBufferPool = cvPixelBufferPool else {
                assertionFailure("Allocation failure: Could not allocate pixel buffer pool")
                return (nil, nil, nil)
            }
            
            preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)
            
            // Get output format description
            var pixelBuffer: CVPixelBuffer?
            var outputFormatDescription: CMFormatDescription?
            let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
            CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &outputFormatDescription)
            }
            pixelBuffer = nil
            
            return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }
    
    private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }
    #endif
#endif
