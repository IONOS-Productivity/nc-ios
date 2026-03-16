// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2018 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import Combine

protocol NCGridCellDelegate: AnyObject {
    func onMenuIntent(with metadata: tableMetadata?)
    func openContextMenu(with metadata: tableMetadata?, button: UIButton, sender: Any)
}

class NCGridCell: UICollectionViewCell, UIGestureRecognizerDelegate, NCCellProtocol {
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var imageFavorite: UIImageView!
    @IBOutlet weak var imageLocal: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelSubinfo: UILabel!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var progressView: UIProgressView!

    #if !EXTENSION
    private var playbackProgressView = PlaybackProgressView()
    #endif

    weak var delegate: NCGridCellDelegate?

    var metadata: tableMetadata? {
        didSet {
            delegate?.openContextMenu(with: metadata, button: buttonMore, sender: self) /* preconfigure UIMenu with each metadata */
        }
    }

    var previewImageView: UIImageView? {
        get { return imageItem }
        set { imageItem = newValue }
    }
    var title: UILabel? {
        get { return labelTitle }
        set { labelTitle = newValue }
    }
    var info: UILabel? {
        get { return labelInfo }
        set { labelInfo = newValue }
    }
    var subInfo: UILabel? {
        get { return labelSubinfo }
        set { labelSubinfo = newValue }
    }
    var statusImageView: UIImageView? {
        get { return imageStatus }
        set { imageStatus = newValue }
    }
    var localImageView: UIImageView? {
        get { return imageLocal }
        set { imageLocal = newValue }
    }
    var favoriteImageView: UIImageView? {
        get { return imageFavorite }
        set { imageFavorite = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let tapObserver = UITapGestureRecognizer(target: self, action: #selector(handleTapObserver(_:)))
        tapObserver.cancelsTouchesInView = false
        tapObserver.delegate = self
        contentView.addGestureRecognizer(tapObserver)

        initCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initCell()
    }

    func initCell() {
        accessibilityHint = nil
        accessibilityLabel = nil
        accessibilityValue = nil
        isAccessibilityElement = true

        imageItem.image = nil
        imageItem.layer.cornerRadius = 6
        imageItem.layer.masksToBounds = true

        imageSelect.isHidden = true
        imageSelect.image = UIImage(resource: .FileSelection.gridItemSelected)
        imageStatus.image = nil
        imageFavorite.image = nil
        imageLocal.image = nil
        labelTitle.text = ""
        labelInfo.text = ""
        labelSubinfo.text = ""

        let longPressedGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gestureRecognizer:)))
        longPressedGesture.minimumPressDuration = 0.5
        longPressedGesture.delegate = self
        longPressedGesture.delaysTouchesBegan = true
        self.addGestureRecognizer(longPressedGesture)

        #if !EXTENSION
        if playbackProgressView.superview == nil {
            addSubview(playbackProgressView)
            playbackProgressView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                playbackProgressView.leadingAnchor.constraint(equalTo: progressView.leadingAnchor),
                playbackProgressView.trailingAnchor.constraint(equalTo: progressView.trailingAnchor),
                playbackProgressView.topAnchor.constraint(equalTo: progressView.topAnchor),
                playbackProgressView.bottomAnchor.constraint(equalTo: progressView.bottomAnchor)
            ])
        }
        #endif
    }

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        return nil
    }

    @objc private func handleTapObserver(_ g: UITapGestureRecognizer) {
        let location = g.location(in: contentView)

        if buttonMore.frame.contains(location) {
            delegate?.onMenuIntent(with: metadata)
        }
    }

    func setButtonMore(image: UIImage) {
        buttonMore.setImage(image, for: .normal)
    }

    func hideImageItem(_ status: Bool) {
        imageItem.isHidden = status
    }

    func hideImageFavorite(_ status: Bool) {
        imageFavorite.isHidden = status
    }

    func hideImageStatus(_ status: Bool) {
        imageStatus.isHidden = status
    }

    func hideImageLocal(_ status: Bool) {
        imageLocal.isHidden = status
    }

    func hideLabelInfo(_ status: Bool) {
        labelInfo.isHidden = status
    }

    func hideLabelSubinfo(_ status: Bool) {
        labelSubinfo.isHidden = status
    }

    func hideButtonMore(_ status: Bool) {
        buttonMore.isHidden = status
    }

    func selected(_ isSelected: Bool, isEditMode: Bool) {
        if isEditMode {
            buttonMore.isHidden = true
            accessibilityCustomActions = nil
        } else {
            buttonMore.isHidden = false
        }
        setBorderForGridViewCell(isSelected: isSelected)
        imageSelect.isHidden = !isSelected
    }

    func writeInfoDateSize(date: NSDate, size: Int64) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current

        labelInfo.text = dateFormatter.string(from: date as Date)
        labelSubinfo.text = NCUtilityFileSystem().transformedSize(size)
    }

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }

    func setIconOutlines() {}
}

#if !EXTENSION
extension NCGridCell: NCCellMedia {
    func setupPlaybackProgress(visible: Bool) {
        playbackProgressView.setupPlaybackProgress(ocId: ocId, visible: visible)
    }
}
#endif

protocol NCGridCellDelegate: AnyObject {
    func tapMoreGridItem(with ocId: String, ocIdTransfer: String, image: UIImage?, sender: Any)
    func longPressGridItem(with ocId: String, ocIdTransfer: String, gestureRecognizer: UILongPressGestureRecognizer)
}

// MARK: - Grid Layout

class NCGridLayout: UICollectionViewFlowLayout {
    var heightLabelPlusButton: CGFloat = 60
    var marginLeftRight: CGFloat = 10
    var column: CGFloat = 3
    var itemWidthDefault: CGFloat = 140

    override init() {
        super.init()

        sectionHeadersPinToVisibleBounds = false

        minimumInteritemSpacing = 1
        minimumLineSpacing = marginLeftRight

        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsets(top: 10, left: marginLeftRight, bottom: 0, right: marginLeftRight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var itemSize: CGSize {
        get {
            if let collectionView = collectionView {
                if collectionView.frame.width < 400 {
                    column = 3
                } else {
                    column = collectionView.frame.width / itemWidthDefault
                }
                let itemWidth: CGFloat = (collectionView.frame.width - marginLeftRight * 2 - marginLeftRight * (column - 1)) / column
                let itemHeight: CGFloat = itemWidth + heightLabelPlusButton
                return CGSize(width: itemWidth, height: itemHeight)
            }
            return CGSize(width: itemWidthDefault, height: itemWidthDefault)
        }
        set {
            super.itemSize = newValue
        }
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
}
