//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit
import RewardsAPI

final class DashboardFactory: DashboardProducing {
    func makeDashboardViewController() -> UIViewController {
        let view = DashboardViewFactory().make()
        
        let api = RewardsAPI.API.shared
        let viewModel = DashboardViewModel(api: api)
        
        return DashboardViewController(
            view: view,
            viewModel: viewModel
        )
    }
    
    func makeErrorViewController(error: Error) -> UIViewController {
        let alertController = UIAlertController(
            title: Localized.errorAlertTitle,
            message: ErrorMessageFactory.message(for: error),
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: Localized.errorAlertCloseButtonTitle, style: .default)
        alertController.addAction(action)
        
        return alertController
    }
}
