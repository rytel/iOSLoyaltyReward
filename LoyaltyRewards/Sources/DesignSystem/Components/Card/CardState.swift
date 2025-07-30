//
// Copyright © 2022 Future Mind. All rights reserved.
//

enum CardState: CustomStringConvertible {
    case active
    case locked
    case unlocked
    case updating

    var description: String {
        switch self {
        case .active: "active"
        case .locked: "locked"
        case .unlocked: "unlocked"
        case .updating: "updating"
        }
    }
}

extension CardState: Equatable {}
