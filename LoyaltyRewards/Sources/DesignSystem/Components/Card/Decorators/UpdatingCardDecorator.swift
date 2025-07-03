//
// Copyright © 2022 Future Mind. All rights reserved.
//


import UIKit

struct UpdatingCardDecorator {
    static func decorate(_ view: CardView) {
        UnlockedCardDecorator.decorate(view)
        addSpinnerToButton(view.button)
    }

    private static func addSpinnerToButton(_ button: Button) {
        button.text = ""
        button.isEnabled = false

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
}
