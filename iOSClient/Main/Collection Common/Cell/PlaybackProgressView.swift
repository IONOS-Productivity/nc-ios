//
//  PlaybackProgressView.swift
//  Nextcloud
//
//  Created by Auto on 09.01.2026.
//  Copyright © 2026 STRATO GmbH. All rights reserved.
//

#if !EXTENSION
import UIKit
import Combine

class PlaybackProgressView: UIView {
    private let progressView: UIProgressView
    private var cancellables = Set<AnyCancellable>()
    private var currentOcId: String?

    override init(frame: CGRect) {
        progressView = UIProgressView()
        super.init(frame: frame)
        setupProgressView()
    }

    required init?(coder: NSCoder) {
        progressView = UIProgressView()
        super.init(coder: coder)
        setupProgressView()
    }

    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        progressView.tintColor = NCBrandColor.shared.brandElement
        progressView.trackTintColor = UIColor(resource: .BurgerMenu.progressBarBackground)
        progressView.isHidden = true
        progressView.progress = 0
    }

    func setupPlaybackProgress(ocId: String, visible: Bool) {
        cancellables.removeAll()
        currentOcId = ocId

        guard visible else {
            progressView.isHidden = true
            progressView.progress = 0
            return
        }

        let mediaCoordinator = NCMediaCoordinator.shared

        mediaCoordinator.positionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                guard let self = self else { return }
                if self.currentOcId == mediaCoordinator.item?.ocId {
                    self.progressView.progress = position
                    self.progressView.isHidden = false
                } else {
                    self.progressView.isHidden = true
                    self.progressView.progress = 0
                }
            }
            .store(in: &cancellables)

        mediaCoordinator.metadataSwitchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, newItem in
                guard let self = self else { return }
                if self.currentOcId == newItem?.ocId {
                    let currentPosition = mediaCoordinator.position
                    self.progressView.progress = currentPosition
                    self.progressView.isHidden = false
                } else {
                    self.progressView.isHidden = true
                    self.progressView.progress = 0
                }
            }
            .store(in: &cancellables)

        mediaCoordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                if self.currentOcId == mediaCoordinator.item?.ocId {
                    switch state {
                    case .stopped, .ended, .error:
                        self.progressView.isHidden = true
                        self.progressView.progress = 0
                    default:
                        self.progressView.isHidden = false
                    }
                }
            }
            .store(in: &cancellables)

        if ocId == mediaCoordinator.item?.ocId {
            let currentPosition = mediaCoordinator.position
            progressView.progress = currentPosition
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
            progressView.progress = 0
        }
    }
}
#endif
