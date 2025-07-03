//
//  Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import UIKit
import OSLog
import RewardsAPI

final class DashboardViewController: UIViewController {
    private let dashboardView: DashboardView
    private let viewModel: DashboardViewModelProtocol

    weak var delegate: DashboardViewControllerDelegate?

    private var cancellables: Set<AnyCancellable> = []
    private var imageLoadingCancellables = Set<AnyCancellable>()
    private var cardData: [CardCarouselView.CardData] = []
    
    private let logger = Logger(subsystem: "com.yourapp.RewardsApp", category: "DashboardViewController")

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
        logger.info("DashboardViewController did load.")
        
        setupNavigationBar()
        setupDelegatesAndTargets()
        setupBindings()
        
        logger.info("Fetching initial data...")
        viewModel.fetchAllData()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = Localized.dashboardTitle
    }
    
    private func setupDelegatesAndTargets() {
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

        viewModel.error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.logger.error("Error received, passing to delegate: \(error.localizedDescription)")
                self?.delegate?.dashboardViewController(didFailWith: error)
            }
            .store(in: &cancellables)
            
        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.logger.debug("isLoading state changed: \(isLoading)")
                if !isLoading {
                    self?.dashboardView.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
            
        Publishers.CombineLatest4(
            viewModel.rewards,
            viewModel.activeRewardIdentifiers,
            viewModel.points,
            viewModel.updatingRewardIDs
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (rewards, activeIDs, userPoints, updatingIDs) in
            self?.logger.info("Received new data snapshot. Updating UI.")
            self?.updateCarousel(with: rewards, activeIDs: activeIDs, userPoints: userPoints, updatingIDs: updatingIDs)
        }
        .store(in: &cancellables)
    }
    
    @objc private func refreshData() {
        logger.info("User initiated pull-to-refresh.")
        viewModel.fetchAllData()
    }
    
    private func updateCarousel(with rewards: [RewardEntity], activeIDs: [String], userPoints: UInt, updatingIDs: Set<String>) {
        imageLoadingCancellables.forEach { $0.cancel() }
        imageLoadingCancellables.removeAll()

        cardData = rewards.map { reward in
            let state: CardState
            if updatingIDs.contains(reward.id) {
                state = .updating
            } else {
                let isActive = activeIDs.contains(reward.id)
                let hasEnoughPoints = userPoints >= reward.pointsCost
                if isActive { state = .active }
                else if hasEnoughPoints { state = .unlocked }
                else { state = .locked }
            }
            let points = UInt(max(0, reward.pointsCost))
            return .init(id: reward.id, title: reward.name, image: nil, state: state, pointsCost: points)
        }
        dashboardView.cardCarousel.cards = cardData

        for (index, reward) in rewards.enumerated() {
            viewModel.loadImage(for: reward)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] image in
                    guard let self, self.cardData.indices.contains(index) else { return }
                    if image != nil {
                        self.logger.debug("Image loaded for reward: \(reward.name)")
                    }
                    self.cardData[index].image = image
                    self.dashboardView.cardCarousel.cards = self.cardData
                }
                .store(in: &imageLoadingCancellables)
        }
    }
}

extension DashboardViewController: CardCarouselViewDelegate {
    func cardCarouselView(_ carouselView: CardCarouselView, didTapButtonInCardWith data: CardCarouselView.CardData) {
        logger.info("User tapped button for reward ID: \(data.id) with state: \(data.state)")
        if data.state == .active {
            viewModel.deactivateReward(with: data.id)
        } else if data.state == .unlocked {
            viewModel.activateReward(with: data.id)
        }
    }
}
