//
// Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import Foundation
import RewardsAPI
import UIKit

final class DashboardViewModel {
    @Published private(set) var rewardsPublisher: [RewardEntity] = []
    @Published private(set) var pointsPublisher: UInt = 0
    @Published private(set) var customerNamePublisher: String = "Guest"
    @Published private(set) var activeRewardIdentifiersPublisher: [String] = []
    @Published private(set) var isLoadingPublisher: Bool = false
    @Published private(set) var errorMessagePublisher: String?

    private var cancellables = Set<AnyCancellable>()
    private let api: RewardsAPI.API

    init(api: RewardsAPI.API = .shared) {
        self.api = api
    }

    private func fetchActiveRewardIdentifiers() {
        api.getActiveRewardIdentifiers()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                    print("Failed to fetch active reward identifiers: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] identifiers in
                self?.activeRewardIdentifiersPublisher = identifiers
            }
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        if let httpError = error as? HttpError {
            self.errorMessagePublisher = switch httpError {
            case .badRequest:
                "Bad request. Please try again."
            case .resourceNotFound:
                "Could not find the requested resource."
            case .serverUnavailable:
                "Server is currently unavailable. Please try again later."
            default:
                "An unexpected error occurred: \(error.localizedDescription)"
            }
        } else {
            self.errorMessagePublisher = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - DashboardViewModelProtocol
extension DashboardViewModel: DashboardViewModelProtocol {
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
    
    func fetchAllData() {
        isLoadingPublisher = true
        errorMessagePublisher = nil

        Publishers.CombineLatest3(
            api.loadRewards(),
            api.loadAvailablePoints(),
            api.loadCustomer()
        )
        .sink { [weak self] completion in
            self?.isLoadingPublisher = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] (rewards, points, customer) in
            self?.rewardsPublisher = rewards
            self?.pointsPublisher = points
            self?.customerNamePublisher = customer.name
        }
        .store(in: &cancellables)

        fetchActiveRewardIdentifiers()
    }

    func loadImage(for reward: RewardEntity) -> AnyPublisher<UIImage?, Never> {
        return api.loadImage(for: reward.coverURL)
            .map { $0 as UIImage? }
            .catch { error -> Just<UIImage?> in
                print("Failed to load image for reward '\(reward.name)': \(error.localizedDescription)")
                return Just(nil)
            }
            .eraseToAnyPublisher()
    }

    func activateReward(with id: String) {
        isLoadingPublisher = true
        errorMessagePublisher = nil

        api.activateReward(with: id)
            .sink { [weak self] completion in
                self?.isLoadingPublisher = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                } else {
                    self?.fetchActiveRewardIdentifiers()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func deactivateReward(with id: String) {
        isLoadingPublisher = true
        errorMessagePublisher = nil

        api.deactivateReward(with: id)
            .sink { [weak self] completion in
                self?.isLoadingPublisher = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                } else {
                    self?.fetchActiveRewardIdentifiers()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func isRewardActive(id: String) -> Bool {
        return activeRewardIdentifiersPublisher.contains(id)
    }
}
