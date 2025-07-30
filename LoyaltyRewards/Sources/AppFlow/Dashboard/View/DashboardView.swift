//
//  Copyright © 2022 Future Mind. All rights reserved.
//

import UIKit

final class DashboardView: UIView {
    private let scrollView = UIScrollView()
    private let mainStackView = UIStackView()

    let backgroundGradientView = GradientView()
    let sectionTitle = SectionTitleView()
    let counterLoop = CounterLoop()
    let cardCarousel = CardCarouselView()
    let bannerCode = BannerCodeView()
    let refreshControl = UIRefreshControl()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        setupLayout()
    }
}

private extension DashboardView {
    func setupLayout() {
        constructHierarchy()
        prepareBackgroundGradientView()
        prepareScrollView()
        prepareMainStackView()
        prepareSectionTitle()
        prepareCounterLoop()
        prepareBannerCode()
        prepareCardCarousel()
    }

    func constructHierarchy() {
        addSubview(backgroundGradientView)
        addSubview(scrollView)
        scrollView.addSubview(mainStackView)

        mainStackView.addArrangedSubview(sectionTitle)
        mainStackView.addArrangedSubview(counterLoop)
        mainStackView.addArrangedSubview(cardCarousel)
        mainStackView.addArrangedSubview(bannerCode)
    }

    func prepareBackgroundGradientView() {
        backgroundGradientView.gradientDirection = .topToBottom
        backgroundGradientView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundGradientView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            backgroundGradientView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            backgroundGradientView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            backgroundGradientView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func prepareScrollView() {
        scrollView.refreshControl = refreshControl
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func prepareMainStackView() {
        mainStackView.axis = .vertical
        mainStackView.spacing = Margin.default
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Margin.medium),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    func prepareSectionTitle() {
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false
    }

    func prepareCounterLoop() {
        counterLoop.translatesAutoresizingMaskIntoConstraints = false
    }

    func prepareCardCarousel() {
        cardCarousel.translatesAutoresizingMaskIntoConstraints = false
    }

    func prepareBannerCode() {
        bannerCode.translatesAutoresizingMaskIntoConstraints = false
    }
}
