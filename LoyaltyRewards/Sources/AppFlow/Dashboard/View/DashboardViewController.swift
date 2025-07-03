//
//  Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import UIKit
import RewardsAPI

final class DashboardViewController: UIViewController {
    private let dashboardView: DashboardView
    private let viewModel: DashboardViewModelProtocol

    private var cancellables: Set<AnyCancellable> = []
    private var cardData: [CardCarouselView.CardData] = []

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        view: DashboardView,
        viewModel: DashboardViewModelProtocol
    ) {
        self.dashboardView = view
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = dashboardView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupDelegatesAndTargets()
        setupBindings()
        
        viewModel.fetchAllData()
    }
}

extension DashboardViewController {
    private func setupNavigationBar() {
        navigationItem.title = Localized.dashboardTitle
    }
    
    func setupDelegatesAndTargets() {
        dashboardView.cardCarousel.delegate = self
        dashboardView.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setupBindings() {
        viewModel.customerName
            .receive(on: DispatchQueue.main)
            .map { Localized.dashboardWelcomeTitle($0) }
            .assign(to: \.title, on: dashboardView.sectionTitle)
            .store(in: &cancellables)

        viewModel.points
            .receive(on: DispatchQueue.main)
            .map { "\($0)" }
            .assign(to: \.points, on: dashboardView.counterLoop)
            .store(in: &cancellables)
            
        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.dashboardView.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
            
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.presentErrorAlert(with: message)
            }
            .store(in: &cancellables)
            
        Publishers.CombineLatest(viewModel.rewards, viewModel.activeRewardIdentifiers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (rewards, activeIDs) in
                self?.updateCarousel(with: rewards, activeIDs: activeIDs)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Methods
private extension DashboardViewController {
    @objc func refreshData() {
        viewModel.fetchAllData()
    }
    
    func updateCarousel(with rewards: [RewardEntity], activeIDs: [String]) {
        cardData = rewards.map { reward in
            let isActive = activeIDs.contains(reward.id)
            let buttonTitle = String(reward.pointsCost)
            return .init(id: reward.id, title: reward.name, image: nil, buttonTitle: buttonTitle)
        }
        dashboardView.cardCarousel.cards = cardData

        for (index, reward) in rewards.enumerated() {
            viewModel.loadImage(for: reward)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] image in
                    guard let self, self.cardData.indices.contains(index) else { return }
                    self.cardData[index].image = image
                    self.dashboardView.cardCarousel.cards = cardData
                }
                .store(in: &cancellables)
        }
    }
    
    func presentErrorAlert(with message: String) {
        let alert = UIAlertController(title: Localized.errorAlertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.errorAlertCloseButtonTitle, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CardCarouselViewDelegate
extension DashboardViewController: CardCarouselViewDelegate {
    func cardCarouselView(_ carouselView: CardCarouselView, didTapButtonInCardWith data: CardCarouselView.CardData) {
        viewModel.isRewardActive(id: data.id) ?
        viewModel.deactivateReward(with: data.id) : viewModel.activateReward(with: data.id)
    }
}
