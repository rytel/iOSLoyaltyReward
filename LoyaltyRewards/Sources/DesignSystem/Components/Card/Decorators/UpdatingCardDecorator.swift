//
// Copyright © 2022 Future Mind. All rights reserved.
//


import UIKit

struct UpdatingCardDecorator {
    static func decorate(_ view: CardView) {
        UnlockedCardDecorator.decorate(view)
        view.button.isEnabled = false
        addSpinnerToImageView(on: view)
    }

    private static func addSpinnerToImageView(on view: CardView) {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        
        let imageView = view.imageView
        imageView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
}
