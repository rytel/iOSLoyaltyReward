//
// Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit

final class CardView: UIView {
    private enum Constants {
        static let buttonWidth: CGFloat = 120
        static let imageViewHeight: CGFloat = 170
    }

    private let mainStackView = UIStackView()
    let imageView = UIImageView()
    private let imageOverlayView = UIView()
    private let titleLabel = UILabel()

    let button = Button()

    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = NSAttributedString(string: newValue, font: titleFont)
        }
    }

    var titleFont: Font {
        didSet {
            titleLabel.font = titleFont.font
            titleLabel.attributedText = NSAttributedString(string: title, font: titleFont)
        }
    }

    var titleColor: UIColor? {
        get {
            return titleLabel.textColor
        }
        set {
            titleLabel.textColor = newValue
        }
    }

    var imageOverlayColor: UIColor? {
        didSet {
            imageOverlayView.backgroundColor = imageOverlayColor
        }
    }

    init() {
        titleFont = Font(font: titleLabel.font)

        super.init(frame: .zero)

        imageOverlayColor = .clear
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CardView {
    private func setupView() {
        constructHierarchy()
        
        prepareRootView()
        prepareMainStackView()
        prepareImageView()
        prepareImageOverlayView()
        prepareTitleLabel()
        prepareButton()
    }

    private func constructHierarchy() {
        let insets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: -Margin.medium,
            right: 0
        )
        embedSubview(mainStackView, edgeInsets: insets)

        imageView.addSubview(imageOverlayView)

        mainStackView.addArrangedSubview(imageView)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(button)
    }

    private func prepareRootView() {
        clipsToBounds = true
        layer.cornerRadius = Margin.extraSmall
    }

    private func prepareMainStackView() {
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.distribution = .equalSpacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func prepareImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageViewHeight)
        ])
    }

    private func prepareImageOverlayView() {
        imageOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            imageOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            imageOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            imageOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
    }

    private func prepareTitleLabel() {
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func prepareButton() {
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Constants.buttonWidth)
        ])
    }
}
