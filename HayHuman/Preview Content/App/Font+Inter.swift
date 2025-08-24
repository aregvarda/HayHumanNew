import SwiftUI

extension Font {
    static func inter(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold:      name = "Inter-Bold"
        case .semibold:  name = "Inter-SemiBold"
        case .medium:    name = "Inter-Medium"
        case .regular:   fallthrough
        default:         name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }
}
//
//  Font+Inter.swift
//  HayHuman
//
//  Created by Арег Варданян on 15.08.2025.
//

