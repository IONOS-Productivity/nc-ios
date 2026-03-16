// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

protocol NCPhotoCellDelegate: AnyObject {
    func onMenuIntent(with metadata: tableMetadata?)
    func openContextMenu(with metadata: tableMetadata?, button: UIButton, sender: Any)
}

class NCPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, NCCellProtocol {
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var imageItemBottom: NSLayoutConstraint!

    weak var delegate: NCPhotoCellDelegate?

    var metadata: tableMetadata? {
        didSet {
            delegate?.openContextMenu(with: metadata, button: buttonMore, sender: self) /* preconfigure UIMenu with each metadata */
        }
    }

    var previewImageView: UIImageView? {
        get { return imageItem }
        set { imageItem = newValue }
    }
    var statusImageView: UIImageView? {
        get { return imageStatus }
        set { imageStatus = newValue }
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

        imageSelect.isHidden = true
        imageSelect.image = UIImage(resource: .FileSelection.gridItemSelected)

        buttonMore.isHidden = true
        buttonMore.menu = nil
        buttonMore.showsMenuAsPrimaryAction = true
        contentView.bringSubviewToFront(buttonMore)
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
//        buttonMore.setImage(image, for: .normal)
        setA11yActions()
    }

    func hideButtonMore(_ status: Bool) {
//        buttonMore.isHidden = status
    }

    func hideImageStatus(_ status: Bool) {
        imageStatus.isHidden = status
    }

    func selected(_ isSelected: Bool, isEditMode: Bool) {
        setBorderForGridViewCell(isSelected: isSelected)
        imageSelect.isHidden = !isSelected
    }

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }
}
