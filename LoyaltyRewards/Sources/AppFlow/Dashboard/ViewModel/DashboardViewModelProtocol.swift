//
// Copyright © 2022 Future Mind. All rights reserved.
//

import Combine
import RewardsAPI
import UIKit

protocol DashboardViewModelProtocol: AnyObject {
    var customerName: AnyPublisher<String, Never> { get }
    var points: AnyPublisher<UInt, Never> { get }
    var rewards: AnyPublisher<[RewardEntity], Never> { get }
    var activeRewardIdentifiers: AnyPublisher<[String], Never> { get }
    var isLoading: AnyPublisher<Bool, Never> { get }
    var errorMessage: AnyPublisher<String?, Never> { get }

    func fetchAllData()
    func loadImage(for reward: RewardEntity) -> AnyPublisher<UIImage?, Never>
    func activateReward(with id: String)
    func deactivateReward(with id: String)
    func isRewardActive(id: String) -> Bool
}
