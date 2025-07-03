//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit

protocol CardCarouselViewDelegate: AnyObject {
    func cardCarouselView(_ carouselView: CardCarouselView, didTapButtonInCardWith data: CardCarouselView.CardData)
    func cardCarouselView(_ carouselView: CardCarouselView, didSelectCardWith data: CardCarouselView.CardData)
}

final class CardCarouselView: UIView {
    struct CardData {
        let id: String
        let title: String
        let image: UIImage?
        let buttonTitle: String
    }

    private enum Constants {
        static let itemSize = CGSize(width: 150, height: 250)
        static let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let minimumLineSpacing: CGFloat = 16
    }

    private let collectionView: UICollectionView
    private var cards: [CardData] {
        didSet {
            collectionView.reloadData()
        }
    }
    weak var delegate: CardCarouselViewDelegate?

    init() {
        let layout = UICollectionViewFlowLayout()
        self.cards = []
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
        collectionView.delegate = self
        collectionView.register(CardCell.self, forCellWithReuseIdentifier: CardCell.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
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
        cell.configure(with: cardData)
        
        // Handle button tap via a closure, which then calls the delegate.
        cell.onButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.delegate?.cardCarouselView(self, didTapButtonInCardWith: cardData)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CardCarouselView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardData = cards[indexPath.item]
        delegate?.cardCarouselView(self, didSelectCardWith: cardData)
    }
}


// MARK: - Private CollectionViewCell
private final class CardCell: UICollectionViewCell {
    static let reuseIdentifier = "CardCell"
    
    private let cardView = CardView()
    
    var onButtonTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with data: CardCarouselView.CardData) {
        cardView.title = data.title
        cardView.image = data.image
        cardView.button.text = data.buttonTitle
    }
    
    private func setupCell() {
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func handleButtonTap() {
        onButtonTapped?()
    }
}
