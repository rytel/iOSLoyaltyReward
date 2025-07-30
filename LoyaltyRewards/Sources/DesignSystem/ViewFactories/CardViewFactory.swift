//
// Copyright © 2022 Future Mind. All rights reserved.
//

struct CardViewFactory {
    func make(for cardState: CardState) -> CardView {
        let view = CardView()
        
        switch cardState {
        case .active:
            ActiveCardDecorator.decorate(view)
            view.button.isEnabled = true
        case .locked:
            LockedCardDecorator.decorate(view)
            view.button.isEnabled = false
        case .unlocked:
            UnlockedCardDecorator.decorate(view)
            view.button.isEnabled = true
        case .updating:
            UpdatingCardDecorator.decorate(view)
            view.button.isEnabled = false
        }
        
        return view
    }
}
