// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2026 Serhii Kaliberda
// SPDX-License-Identifier: GPL-3.0-or-later

enum ItemShareState {
    case notShared
    case sharedOnMe
    case sharedInternally
    case sharedByLink

    static func state(by metadata: tableMetadata, isShare: Bool) -> ItemShareState {
        if isShare {
            return .sharedOnMe
        }

        if metadata.shareType.isEmpty {
            return .notShared
        }

        if metadata.shareType.contains(3) {
            return .sharedByLink
        }

        return .sharedInternally
    }

    var iconImage: UIImage {
        let imageCache = NCImageCache.shared
        switch self {
        case .notShared: 		return imageCache.getImageCanShare()
        case .sharedOnMe: 		return imageCache.getIconSharedWithMe()
        case .sharedInternally: return imageCache.getIconSharedInternally()
        case .sharedByLink: 	return imageCache.getIconSharedByLink()
        }
    }

    var folderImage: UIImage {
        let imageCache = NCImageCache.shared
        switch self {
        case .notShared: 		return imageCache.getFolder()
        case .sharedOnMe: 		return imageCache.getFolderSharedWithMe()
        case .sharedInternally: return imageCache.getFolderSharedInternally()
        case .sharedByLink: 	return imageCache.getFolderSharedByLink()
        }
    }
}
