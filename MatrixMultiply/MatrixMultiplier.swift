//
//  MatrixMultiplier.swift
//  MatrixMultiply
//
//  Created by fadi on 13/07/2021.
//

import UIKit

class VMMemory {
    static func allocate(size: Int) -> Data? {
        var address: vm_address_t = 0
        let bufferFullSize = vm_size_t(((size / 4096) + 1) * 4096)
        vm_allocate(mach_task_self_,
                    &address,
                    bufferFullSize,
                    Int32(0))
        if address == 0 {
            vm_allocate(mach_task_self_,
                        &address,
                        bufferFullSize,
                        Int32(1))
        }
        guard address != 0,
              let pointer = UnsafeMutableRawPointer.init(bitPattern: address) else {
            return nil
        }
        return Data(bytesNoCopy: pointer, count: size, deallocator: Data.Deallocator.custom({_,_ in
            vm_deallocate(mach_task_self_, address, bufferFullSize)
        }))
    }
}

class MutableMatrix {
    let width: Int
    let height: Int
    fileprivate var data: Data
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.data = VMMemory.allocate(size: width * height * (32 / 8))!
    }
    
    subscript(x: Int, y: Int) -> Float32 {
        get {
            precondition(x >= 0 && x < width)
            precondition(y >= 0 && y < height)
            return data.withUnsafeBytes {
                $0.bindMemory(to: Float32.self)[(y * width) + x]
            }
        }
        set {
            precondition(x >= 0 && x < width)
            precondition(y >= 0 && y < height)
            return data.withUnsafeMutableBytes {
                $0.bindMemory(to: Float32.self)[(y * width) + x] = newValue
            }
        }
    }
}

struct Matrix {
    private var wrapee: MutableMatrix
    var width: Int { get { wrapee.width } }
    var height: Int { get { wrapee.height } }

    init(wrapee: MutableMatrix) {
        self.wrapee = wrapee
    }
    
    subscript(x: Int, y: Int) -> Float32 {
        get {
            return wrapee[x, y]
        }
    }
}

extension MutableMatrix {
    func unsafeMakeBuffer(with device: MTLDevice) -> MTLBuffer? {
        return data.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress else { return nil }
            let memSize = (Int(size.width) * Int(size.height) * (32/8))
            return device.makeBuffer(bytesNoCopy: address,
                                     length: Int(((memSize / 4096) + 1) * 4096),
                                     options: [.cpuCacheModeWriteCombined, .storageModeShared],
                                     deallocator: { _,_  in
                                        _ = self
                                     })
        }
    }
}

extension Matrix {
    func unsafeMakeBuffer(with device: MTLDevice) -> MTLBuffer? {
        return wrapee.unsafeMakeBuffer(with: device)
    }
}

protocol MatrixMultiplier {
    func multiply(matrix1: Matrix, matrix2: Matrix,
                  completionHandler: @escaping (Matrix) -> Void)
}

struct Size {
    let width: Int32
    let height: Int32
}

extension MutableMatrix {
    var size: Size { get { Size(width: Int32(width), height: Int32(height)) } }
}

extension Matrix {
    var size: Size { get { wrapee.size } }
}

struct Parameters {
    let matrix1Buffer: MTLBuffer
    let matrix2Buffer: MTLBuffer
    let resultBuffer: MTLBuffer
    let sizesBuffer: MTLBuffer
    
    func assignToEncoder(commandEncoder: MTLComputeCommandEncoder) {
        commandEncoder.setBuffer(matrix1Buffer, offset: 0, index: Int(MATRIX_1_POSITION))
        commandEncoder.setBuffer(matrix2Buffer, offset: 0, index: Int(MATRIX_2_POSITION))
        commandEncoder.setBuffer(resultBuffer, offset: 0, index: Int(RESULT_MATRIX_POSITION))
        commandEncoder.setBuffer(sizesBuffer, offset: 0, index: Int(SIZES_POSITION))
    }
}

class MatrixMultiplierMetal: MatrixMultiplier {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState
    
    init?(device: MTLDevice) {
        self.device = device
        guard let defaultLibrary = device.makeDefaultLibrary(),
              let function = defaultLibrary.makeFunction(name: FUNCTION_NAME_STRING),
              let computePipeline = try? device.makeComputePipelineState(function: function) else {
            return nil
        }
        
        self.computePipeline = computePipeline
    }
    
    func multiply(matrix1: Matrix, matrix2: Matrix,
                  completionHandler: @escaping (Matrix) -> Void) {
        
        let resultMatrix = MutableMatrix(width: matrix2.width,
                                         height: matrix1.height)
        
        struct Sizes {
            let sizes: [Int32]
            
            init(sizeOfMatrix1: Size, sizeOfMatrix2: Size) {
                sizes = [sizeOfMatrix1.width, sizeOfMatrix1.height,
                         sizeOfMatrix2.width, sizeOfMatrix2.height]
            }
        }
                
        let sizes = Sizes(sizeOfMatrix1: matrix1.size,
                          sizeOfMatrix2: matrix2.size)
        
        guard let matrix1Buffer = matrix1.unsafeMakeBuffer(with: device),
              let matrix2Buffer = matrix2.unsafeMakeBuffer(with: device),
              let resultBuffer = resultMatrix.unsafeMakeBuffer(with: device),
              let sizesBuffer = device.makeBuffer(bytes: sizes.sizes, length: sizes.sizes.count * 4, options: .storageModeShared),
              let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return
        }
        commandEncoder.setComputePipelineState(computePipeline)
        
        let parameters = Parameters(matrix1Buffer: matrix1Buffer,
                                    matrix2Buffer: matrix2Buffer,
                                    resultBuffer: resultBuffer,
                                    sizesBuffer: sizesBuffer)
        
        parameters.assignToEncoder(commandEncoder: commandEncoder)
        
        commandEncoder.dispatchThreadgroups(
            MTLSize(width: resultMatrix.width,
                    height: resultMatrix.height,
                    depth: 1),
            threadsPerThreadgroup: MTLSize(
                width: 1,
                height: 1,
                depth: 1))
        
//        commandEncoder.dispatchThreadgroups(
//            MTLSize(
//                width: 1,
//                height: 1,
//                depth: 1),
//            threadsPerThreadgroup: MTLSize(width: resultMatrix.width,
//                    height: resultMatrix.height,
//                    depth: 1))
        
        commandBuffer.addCompletedHandler { a in
//            print(resultBuffer.contents().assumingMemoryBound(to: Float.self).advanced(by: 3).pointee)
            print(a.error.flatMap { ($0 as NSError).code })
            completionHandler(Matrix(wrapee: resultMatrix))
        }
        commandEncoder.endEncoding()
        commandBuffer.commit()

    }
}


class MatrixMultipliesMaths: MatrixMultiplier {
    func multiply(matrix1: Matrix,
                  matrix2: Matrix,
                  completionHandler: @escaping (Matrix) -> Void) {
        let result = MutableMatrix(width: matrix2.width,
                                   height: matrix1.height)
        for x in 0..<result.width {
            for y in 0..<result.height {
                var sum = Float(0)
                for i in 0..<result.width {
                    sum += (matrix1[i, y]) * (matrix2[x, i])
                }
                result[x, y] = sum
            }
        }
        completionHandler(Matrix.init(wrapee: result))
    }
}
