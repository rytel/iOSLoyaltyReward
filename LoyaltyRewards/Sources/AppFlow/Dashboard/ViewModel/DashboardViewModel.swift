//
// Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import Foundation
import RewardsAPI
import UIKit
import OSLog

final class DashboardViewModel: DashboardViewModelProtocol {
    @Published private(set) var rewardsPublisher: [RewardEntity] = []
    @Published private(set) var pointsPublisher: UInt = 0
    @Published private(set) var customerNamePublisher: String = "Guest"
    @Published private(set) var activeRewardIdentifiersPublisher: [String] = []
    @Published private(set) var isLoadingPublisher: Bool = false
    @Published private(set) var errorPublisher: Error?
    @Published private(set) var updatingRewardIDsPublisher: Set<String> = []

    private var cancellables = Set<AnyCancellable>()
    private var fetchIdentifiersCancellable: AnyCancellable?
    private var fetchPointsCancellable: AnyCancellable?
    
    private let api: RewardsAPI.API
    private let imageCache = NSCache<NSURL, UIImage>()
    private let logger = Logger(subsystem: "com.yourapp.RewardsApp", category: "DashboardViewModel")

    init(api: RewardsAPI.API) {
        self.api = api
        logger.info("DashboardViewModel initialized. Fetching initial data...")
        fetchAllData()
    }

    private func fetchActiveRewardIdentifiers() {
        logger.debug("Fetching active reward identifiers...")
        fetchIdentifiersCancellable?.cancel()
        fetchIdentifiersCancellable = api.getActiveRewardIdentifiers()
            .retry(2)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.error("Failed to fetch active reward identifiers: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }, receiveValue: { [weak self] identifiers in
                self?.logger.debug("Successfully fetched \(identifiers.count) active reward identifiers.")
                self?.activeRewardIdentifiersPublisher = identifiers
            })
    }
    
    private func fetchPoints() {
        logger.debug("Fetching user points...")
        fetchPointsCancellable?.cancel()
        fetchPointsCancellable = api.loadAvailablePoints()
            .retry(2)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.error("Failed to fetch points: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }, receiveValue: { [weak self] points in
                self?.logger.debug("Successfully fetched points: \(points).")
                self?.pointsPublisher = points
            })
    }

    private func handleError(_ error: Error) {
        logger.error("Handling error: \(error.localizedDescription)")
        self.errorPublisher = error
    }
    
    var customerName: AnyPublisher<String, Never> { $customerNamePublisher.eraseToAnyPublisher() }
    var points: AnyPublisher<UInt, Never> { $pointsPublisher.eraseToAnyPublisher() }
    var rewards: AnyPublisher<[RewardsAPI.RewardEntity], Never> { $rewardsPublisher.eraseToAnyPublisher() }
    var activeRewardIdentifiers: AnyPublisher<[String], Never> { $activeRewardIdentifiersPublisher.eraseToAnyPublisher() }
    var isLoading: AnyPublisher<Bool, Never> { $isLoadingPublisher.eraseToAnyPublisher() }
    var error: AnyPublisher<Error?, Never> { $errorPublisher.eraseToAnyPublisher() }
    var updatingRewardIDs: AnyPublisher<Set<String>, Never> { $updatingRewardIDsPublisher.eraseToAnyPublisher() }
    
    func fetchAllData() {
        logger.info("fetchAllData triggered.")
        isLoadingPublisher = true
        errorPublisher = nil
        
        Publishers.CombineLatest4(
            api.loadRewards().retry(3),
            api.loadAvailablePoints().retry(3),
            api.loadCustomer().retry(3),
            api.getActiveRewardIdentifiers().retry(3)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoadingPublisher = false
            if case .failure(let error) = completion {
                self?.logger.error("fetchAllData failed: \(error.localizedDescription)")
                self?.handleError(error)
            } else {
                self?.logger.info("fetchAllData completed successfully.")
            }
        } receiveValue: { [weak self] (rewards, points, customer, activeIDs) in
            self?.logger.info("Received data from fetchAllData. Updating publishers.")
            self?.rewardsPublisher = rewards
            self?.pointsPublisher = points
            self?.customerNamePublisher = customer.name
            self?.activeRewardIdentifiersPublisher = activeIDs
        }
        .store(in: &cancellables)
    }
    
    func loadImage(for reward: RewardEntity) -> AnyPublisher<UIImage?, Never> {
        let cacheKey = reward.coverURL as NSURL
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            logger.debug("Image for reward '\(reward.name)' found in cache.")
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        logger.debug("Image for reward '\(reward.name)' not in cache. Fetching from network.")
        return api.loadImage(for: reward.coverURL)
            .map { downloadedImage in
                self.logger.debug("Successfully downloaded image for reward '\(reward.name)'. Caching.")
                self.imageCache.setObject(downloadedImage, forKey: cacheKey)
                return downloadedImage
            }
            .catch { error -> Just<UIImage?> in
                self.logger.error("Failed to load image for reward '\(reward.name)': \(error.localizedDescription)")
                return Just(nil)
            }
            .eraseToAnyPublisher()
    }
    
    func activateReward(with id: String) {
        logger.info("Activating reward with ID: \(id)")
        updatingRewardIDsPublisher.insert(id)
        errorPublisher = nil
        
        api.activateReward(with: id)
            .retry(2)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.updatingRewardIDsPublisher.remove(id)
                if case .failure(let error) = completion {
                    self?.logger.error("Failed to activate reward with ID \(id): \(error.localizedDescription)")
                    self?.handleError(error)
                } else {
                    self?.logger.info("Successfully activated reward with ID: \(id). Refreshing data.")
                    self?.fetchActiveRewardIdentifiers()
                    self?.fetchPoints()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func deactivateReward(with id: String) {
        logger.info("Deactivating reward with ID: \(id)")
        updatingRewardIDsPublisher.insert(id)
        errorPublisher = nil
        
        api.deactivateReward(with: id)
            .retry(2)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.updatingRewardIDsPublisher.remove(id)
                if case .failure(let error) = completion {
                    self?.logger.error("Failed to deactivate reward with ID \(id): \(error.localizedDescription)")
                    self?.handleError(error)
                } else {
                    self?.logger.info("Successfully deactivated reward with ID: \(id). Refreshing data.")
                    self?.fetchActiveRewardIdentifiers()
                    self?.fetchPoints()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func isRewardActive(id: String) -> Bool {
        return activeRewardIdentifiersPublisher.contains(id)
    }
}
