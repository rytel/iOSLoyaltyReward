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
    private var imageLoadingCancellables = Set<AnyCancellable>()
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

// MARK: - Setup & Bindings
private extension DashboardViewController {
    func setupNavigationBar() {
        navigationItem.title = Localized.dashboardTitle
    }
    
    func setupDelegatesAndTargets() {
        dashboardView.cardCarousel.delegate = self
        dashboardView.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    func setupBindings() {
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
            
        Publishers.CombineLatest3(viewModel.rewards, viewModel.activeRewardIdentifiers, viewModel.points)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (rewards, activeIDs, userPoints) in
                self?.updateCarousel(with: rewards, activeIDs: activeIDs, userPoints: userPoints)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Methods
private extension DashboardViewController {
    @objc func refreshData() {
        viewModel.fetchAllData()
    }
    
    func updateCarousel(with rewards: [RewardEntity], activeIDs: [String], userPoints: UInt) {
        imageLoadingCancellables.forEach { $0.cancel() }
        imageLoadingCancellables.removeAll()

        cardData = rewards.map { reward in
            let isActive = activeIDs.contains(reward.id)
            let hasEnoughPoints = userPoints >= reward.pointsCost

            let state: CardState
            if isActive {
                state = .active
            } else if hasEnoughPoints {
                state = .unlocked
            } else {
                state = .locked
            }
            
            return .init(id: reward.id, title: reward.name, image: nil, state: state, pointsCost: UInt(reward.pointsCost))
        }
        dashboardView.cardCarousel.cards = cardData

        for (index, reward) in rewards.enumerated() {
            viewModel.loadImage(for: reward)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] image in
                    guard let self, self.cardData.indices.contains(index) else { return }
                    self.cardData[index].image = image
                    self.dashboardView.cardCarousel.cards = self.cardData
                }
                .store(in: &imageLoadingCancellables)
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
        if data.state == .active {
            viewModel.deactivateReward(with: data.id)
        } else if data.state == .unlocked {
            viewModel.activateReward(with: data.id)
        }
    }
}
