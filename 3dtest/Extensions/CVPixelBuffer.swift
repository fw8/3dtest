//
//  Extension.swift
//  DepthMapDemo
//
//  Created by Florian Wolpert on 20.12.20.
//

import Foundation
import CoreImage


extension CVPixelBuffer {
    
    func exportAsArray() -> [[Float32]] {

        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        var floatArray = Array(repeating: Array(repeating: Float32(0.0), count: height), count: width)
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
        
        for y in stride(from: 0, to: height, by: 1) {
            for x in stride(from: 0, to: width, by: 1) {
                floatArray[x][y] = floatBuffer[y * width + x]
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        return floatArray
    }
}

