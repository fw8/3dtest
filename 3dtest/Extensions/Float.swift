//
//  Float.swift
//  3dtest
//
//  Created by Florian Wolpert on 02.01.21.
//

// some helpfull extensions to convert between radian and degree
extension Float {
    func inDegree() -> Float {
        return self * 180 / .pi
    }
    
    func inRadians() -> Float {
        return self * .pi / 180
    }
}
