//
// Copyright © 2022 Future Mind. All rights reserved.
//


import UIKit

struct UpdatingCardDecorator {
    static func decorate(_ view: CardView) {
        view.backgroundColor = AppColor.cardUnlockedBackground
        view.imageOverlayColor = AppColor.cardUnlockedImageOverlay

        view.titleFont = .applicationFont(ofSize: .m, trait: DefaultFontTrait.bold)
        view.titleColor = AppColor.cardUnlockedTitle

        hideButtonAndShowSpinner(on: view)
    }

    private static func hideButtonAndShowSpinner(on view: CardView) {
        view.button.isHidden = true
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.button.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.button.centerYAnchor)
        ])

        activityIndicator.startAnimating()
    }
}
