//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit

final class CardCell: UICollectionViewCell {
    static let reuseIdentifier = "CardCell"
    
    private var cardView: CardView?
    private let factory = CardViewFactory()
    
    var onButtonTapped: (() -> Void)?

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
        newCardView.image = data.image
        newCardView.button.text = String(data.pointsCost) + Localized.dashboardPointsSuffix
        
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
        cardView?.removeFromSuperview()
        cardView = nil
        onButtonTapped = nil
    }
}
