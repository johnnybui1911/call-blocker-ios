import SwiftUI
import UIKit

enum Theme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.08, blue: 0.07, alpha: 1)
            : UIColor(red: 0.957, green: 0.941, blue: 0.910, alpha: 1)
    })

    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1)
            : UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1)
    })

    static let muted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.73, green: 0.68, blue: 0.61, alpha: 1)
            : UIColor(red: 0.40, green: 0.35, blue: 0.31, alpha: 1)
    })

    static let seal = Color(red: 0.62, green: 0.18, blue: 0.16)
    static let ok = Color(red: 0.15, green: 0.42, blue: 0.30)
    static let warn = Color(red: 0.55, green: 0.36, blue: 0.08)
}
