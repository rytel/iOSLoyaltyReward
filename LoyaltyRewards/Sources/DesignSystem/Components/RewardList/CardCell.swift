//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit
import Combine

final class CardCell: UICollectionViewCell {
    static let reuseIdentifier = "CardCell"
    
    private var cardView: CardView?
    private let factory = CardViewFactory()
    private var imageLoadingCancellable: AnyCancellable?
    
    var onButtonTapped: (() -> Void)?
    var imageLoader: ((String) -> AnyPublisher<UIImage?, Never>)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with data: CardCarouselView.CardData) {
        cardView?.removeFromSuperview()
        let newCardView = factory.make(for: data.state)
        self.cardView = newCardView
        
        newCardView.title = data.title
        newCardView.button.text = String(data.pointsCost) + Localized.dashboardPointsSuffix
        
        // Set placeholder initially, then load image lazily
        newCardView.image = data.image
        
        // Load image on-demand if not already loaded and imageLoader is available
        if data.image == nil, let imageLoader = imageLoader {
            loadImageLazily(for: data.imageURL, into: newCardView, with: imageLoader)
        }
        
        contentView.addSubview(newCardView)
        setupConstraints(for: newCardView)
        
        newCardView.button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }
    
    private func setupConstraints(for view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func handleButtonTap() {
        onButtonTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadingCancellable?.cancel()
        imageLoadingCancellable = nil
        cardView?.removeFromSuperview()
        cardView = nil
        onButtonTapped = nil
        imageLoader = nil
    }
    
    private func loadImageLazily(for url: String, into cardView: CardView, with imageLoader: (String) -> AnyPublisher<UIImage?, Never>) {
        imageLoadingCancellable?.cancel()
        imageLoadingCancellable = imageLoader(url)
            .receive(on: DispatchQueue.main)
            .sink { [weak cardView] image in
                cardView?.image = image
            }
    }
}
