//
// Copyright © 2022 Future Mind. All rights reserved.
//

enum CardState {
    case active
    case locked
    case unlocked
    case updating
}

extension CardState: Equatable {}
