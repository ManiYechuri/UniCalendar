import SwiftUI

enum Typography {
    
    static let regular = "Montserrat-Regular"
    static let medium  = "Montserrat-Medium"
    static let semibold = "Montserrat-SemiBold"
    static let bold = "Montserrat-Bold"
    
    
    static let h1 = Font.custom(semibold, size: 40)
    static let h2 = Font.custom(bold, size: 28)
    static let body = Font.custom(regular, size: 16)
    static let bodyMedium = Font.custom(regular, size: 16)
    static let subheadline = Font.custom(medium, size: 14)
    static let footer = Font.custom(medium, size: 10)
    static let f35 = Font.custom(semibold, size: 35)
    static let f18Bold = Font.custom(bold, size: 18)
    static let f14SemiBold = Font.custom(semibold, size: 14)
    static let f12Regular = Font.custom(regular, size: 12)
}

