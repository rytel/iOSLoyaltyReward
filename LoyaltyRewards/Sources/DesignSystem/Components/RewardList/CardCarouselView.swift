//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit
import Combine

protocol CardCarouselViewDelegate: AnyObject {
    func cardCarouselView(_ carouselView: CardCarouselView, didTapButtonInCardWith data: CardCarouselView.CardData)
}

final class CardCarouselView: UIView {
    struct CardData {
        var id: String
        let title: String
        var image: UIImage?
        let state: CardState
        let pointsCost: UInt
        let imageURL: String
    }

    private enum Constants {
        static let itemSize = CGSize(width: 200, height: 286)
        static let sectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let minimumLineSpacing: CGFloat = 24
        static let collectionViewHeight: CGFloat = itemSize.height + sectionInsets.top + sectionInsets.bottom
    }

    private let collectionView: UICollectionView
    var cards: [CardData] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    weak var delegate: CardCarouselViewDelegate?
    var imageLoader: ((String) -> AnyPublisher<UIImage?, Never>)?

    init() {
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
private extension CardCarouselView {
    func setupView() {
        constructHierarchy()
        prepareCollectionView()
    }

    func constructHierarchy() {
        addSubview(collectionView)
    }

    func prepareCollectionView() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = Constants.itemSize
            layout.minimumLineSpacing = Constants.minimumLineSpacing
            layout.sectionInset = Constants.sectionInsets
        }
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(CardCell.self, forCellWithReuseIdentifier: CardCell.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: Constants.collectionViewHeight)
        ])
    }
}

// MARK: - UICollectionViewDataSource
extension CardCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCell.reuseIdentifier, for: indexPath) as? CardCell else {
            return UICollectionViewCell()
        }
        
        let cardData = cards[indexPath.item]
        cell.imageLoader = imageLoader
        cell.configure(with: cardData)
        
        cell.onButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.delegate?.cardCarouselView(self, didTapButtonInCardWith: cardData)
        }
        
        return cell
    }
}
