//
//  UIColor+palette.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/20/22.
//

import UIKit

extension UIColor {
    
    // cold0 = warmest, cold3 = coldest
    static let cold0 = UIColor(red: 138/255.0, green: 167/255.0, blue: 160/255.0, alpha: 1.0)
    static let cold1 = UIColor(red: 73/255.0, green: 134/255.0, blue: 147/255.0, alpha: 1.0)
    static let cold2 = UIColor(red: 53/255.0, green: 107/255.0, blue: 135/255.0, alpha: 1.0)
    static let cold3 = UIColor(red: 21/255.0, green: 43/255.0, blue: 80/255.0, alpha: 1.0)
    
    // warm0 = coldest, warm3 = hottest
    static let warm0 = UIColor(red: 240/255.0, green: 222/255.0, blue: 184/255.0, alpha: 1.0)
    static let warm1 = UIColor(red: 227/255.0, green: 167/255.0, blue: 117/255.0, alpha: 1.0)
    static let warm2 = UIColor(red: 218/255.0, green: 116/255.0, blue: 71/255.0, alpha: 1.0)
    static let warm3 = UIColor(red: 198/255.0, green: 72/255.0, blue: 50/255.0, alpha: 1.0)
    
    static func colorFor(temperature: Measurement<UnitTemperature>) -> UIColor {
        let fahrenheit = temperature.converted(to: .fahrenheit).value
        
        switch (fahrenheit) {
        case ..<20:
            return .cold3
        case 20..<30:
            return .cold2
        case 30..<40:
            return .cold1
        case 40..<50:
            return .cold0
        case 60..<70:
            return .warm0
        case 70..<80:
            return .warm1
        case 80..<90:
            return .warm2
        case 90...:
            return .warm3
        default:
            return .warm0
        }
        
    }
    
}
