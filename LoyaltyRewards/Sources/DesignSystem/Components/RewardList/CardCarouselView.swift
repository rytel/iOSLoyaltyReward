// MARK: - View Implementation
final class CardCarouselView: UIView {
    
    // A simple data structure to decouple the view from a specific business model.
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

    // MARK: - Private Properties
    private let collectionView: UICollectionView
    private var cards: [CardData] = []
    
    weak var delegate: CardCarouselViewDelegate?

    // MARK: - Initializers
    init() {
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Configuration
    func configure(with cards: [CardData]) {
        self.cards = cards
        collectionView.reloadData()
        // Scroll to the beginning when new data is set.
        if !cards.isEmpty {
            collectionView.setContentOffset(.zero, animated: false)
        }
    }
}

// MARK: - Setup Methods
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
        cardView.button.setTitle(data.buttonTitle, for: .normal)
        cardView.titleColor = .darkText // Example styling
        cardView.backgroundColor = .white // Example styling
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
