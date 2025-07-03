//
// Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import Foundation
import RewardsAPI
import UIKit

import Combine
import Foundation
import RewardsAPI
import UIKit

final class DashboardViewModel: DashboardViewModelProtocol {
    @Published private(set) var rewardsPublisher: [RewardEntity] = []
    @Published private(set) var pointsPublisher: UInt = 0
    @Published private(set) var customerNamePublisher: String = "Guest"
    @Published private(set) var activeRewardIdentifiersPublisher: [String] = []
    @Published private(set) var isLoadingPublisher: Bool = false
    @Published private(set) var errorMessagePublisher: String?
    @Published private(set) var updatingRewardIDsPublisher: Set<String> = []

    private var cancellables = Set<AnyCancellable>()
    private var fetchIdentifiersCancellable: AnyCancellable?
    private var fetchPointsCancellable: AnyCancellable?
    
    private let api: RewardsAPI.API
    private let imageCache = NSCache<NSURL, UIImage>()

    init(api: RewardsAPI.API = .shared) {
        self.api = api
    }

    private func fetchActiveRewardIdentifiers() {
        fetchIdentifiersCancellable?.cancel()
        fetchIdentifiersCancellable = api.getActiveRewardIdentifiers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] identifiers in
                self?.activeRewardIdentifiersPublisher = identifiers
            })
    }
    
    private func fetchPoints() {
        fetchPointsCancellable?.cancel()
        fetchPointsCancellable = api.loadAvailablePoints()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] points in
                self?.pointsPublisher = points
            })
    }

    private func handleError(_ error: Error) {
        self.errorMessagePublisher = ErrorMessageFactory.message(for: error)
    }
    
    var customerName: AnyPublisher<String, Never> {
        $customerNamePublisher.eraseToAnyPublisher()
    }
    
    var points: AnyPublisher<UInt, Never> {
        $pointsPublisher.eraseToAnyPublisher()
    }
    
    var rewards: AnyPublisher<[RewardsAPI.RewardEntity], Never> {
        $rewardsPublisher.eraseToAnyPublisher()
    }
    
    var activeRewardIdentifiers: AnyPublisher<[String], Never> {
        $activeRewardIdentifiersPublisher.eraseToAnyPublisher()
    }
    
    var isLoading: AnyPublisher<Bool, Never> {
        $isLoadingPublisher.eraseToAnyPublisher()
    }
    
    var errorMessage: AnyPublisher<String?, Never> {
        $errorMessagePublisher.eraseToAnyPublisher()
    }
    
    var updatingRewardIDs: AnyPublisher<Set<String>, Never> {
        $updatingRewardIDsPublisher.eraseToAnyPublisher()
    }
    
    func fetchAllData() {
        isLoadingPublisher = true
        errorMessagePublisher = nil

        Publishers.CombineLatest4(
            api.loadRewards(),
            api.loadAvailablePoints(),
            api.loadCustomer(),
            api.getActiveRewardIdentifiers()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoadingPublisher = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] (rewards, points, customer, activeIDs) in
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
            return Just(cachedImage)
                .eraseToAnyPublisher()
        }

        return api.loadImage(for: reward.coverURL)
            .map { downloadedImage in
                self.imageCache.setObject(downloadedImage, forKey: cacheKey)
                return downloadedImage
            }
            .catch { error -> Just<UIImage?> in
                print("Failed to load image for reward '\(reward.name)': \(error.localizedDescription)")
                return Just(nil)
            }
            .eraseToAnyPublisher()
    }

    func activateReward(with id: String) {
           updatingRewardIDsPublisher.insert(id)
           errorMessagePublisher = nil

           api.activateReward(with: id)
               .receive(on: DispatchQueue.main)
               .sink { [weak self] completion in
                   self?.updatingRewardIDsPublisher.remove(id)
                   
                   if case .failure(let error) = completion {
                       self?.handleError(error)
                   } else {
                       self?.fetchActiveRewardIdentifiers()
                       self?.fetchPoints()
                   }
               } receiveValue: { _ in }
               .store(in: &cancellables)
       }

       func deactivateReward(with id: String) {
           updatingRewardIDsPublisher.insert(id)
           errorMessagePublisher = nil

           api.deactivateReward(with: id)
               .receive(on: DispatchQueue.main)
               .sink { [weak self] completion in
                   self?.updatingRewardIDsPublisher.remove(id)

                   if case .failure(let error) = completion {
                       self?.handleError(error)
                   } else {
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
