//
//  UIDevice+VirtualOrientation.swift
//  Nextcloud
//
//  Created by Vitaliy Tolkach on 23.04.2025.
//  Copyright © 2025 STRATO GmbH. All rights reserved.
//

import UIKit

extension UIDevice {
	var isVirtualOrientationLandscape: Bool {
		guard !UIDevice.current.orientation.isLandscape else { return true }
		if let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.windowScene?.interfaceOrientation {
			return orientation.isLandscape
		}
		return false
	}
}
