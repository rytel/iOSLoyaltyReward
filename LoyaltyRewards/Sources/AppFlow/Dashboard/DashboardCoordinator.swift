//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit

final class DashboardCoordinator: Coordinator {
    private let dashboardFactory: DashboardProducing
    private var dashboardViewController: UIViewController

    override var initialViewController: UIViewController {
        return dashboardViewController
    }

    init(dashboardFactory: DashboardProducing) {
        self.dashboardFactory = dashboardFactory
        self.dashboardViewController = dashboardFactory.makeDashboardViewController()
        
        super.init()
        (self.dashboardViewController as? DashboardViewController)?.delegate = self
    }
}

extension DashboardCoordinator: DashboardViewControllerDelegate {
    func dashboardViewController(didFailWith error: Error) {
        let errorViewController = dashboardFactory.makeErrorViewController(error: error)
        initialViewController.present(errorViewController, animated: true)
    }
}
