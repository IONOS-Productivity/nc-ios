//
//  NCBrand-IONOS.swift
//  Nextcloud
//
//  Created by Mariia Perehozhuk on 26.06.2024.
//  Copyright © 2024 STRATO GmbH
//

import Foundation
import UIKit

class NCBrandOptionsIONOS: NCBrandOptions, @unchecked Sendable {

	private let custom_brand = "IONOS HiDrive Next"
	private let custom_textCopyrightNextcloudiOS = "HiDrive Next iOS %@ © 2025"
	private let custom_loginBaseUrl = "https://storage.ionos.fr"
	private let custom_privacy = "https://wl.hidrive.com/easy/ios/privacy.html"
	private let custom_sourceCode = "https://wl.hidrive.com/easy/0181"

	
	//MARK: - override custom values if not default (changed by Brander)
	override var brand: String {
		get {
			if super.brand == "Nextcloud" {
				return custom_brand
			}
			return super.brand
		}
		set {
			super.brand = newValue
		}
	}
	
	override var textCopyrightNextcloudiOS: String {
		get {
			if super.textCopyrightNextcloudiOS == "Nextcloud Hydrogen for iOS %@ © 2025" {
				return custom_textCopyrightNextcloudiOS
			}
			return super.textCopyrightNextcloudiOS
		}
		set {
			super.textCopyrightNextcloudiOS = newValue
		}
	}
	
	override var loginBaseUrl: String {
		get {
			if super.loginBaseUrl == "https://cloud.nextcloud.com" {
				return custom_loginBaseUrl
			}
			return super.loginBaseUrl
		}
		set {
			super.loginBaseUrl = newValue
		}
	}
	
	override var privacy: String {
		get {
			if super.privacy == "https://nextcloud.com/privacy" {
				return custom_privacy
			}
			return super.privacy
		}
		set {
			super.privacy = newValue
		}
	}
	
	override var sourceCode: String {
		get {
			if super.sourceCode == "https://github.com/nextcloud/ios" {
				return custom_sourceCode
			}
			return super.sourceCode
		}
		set {
			super.sourceCode = newValue
		}
	}
	
	//MARK: -
	override init() {
		super.init()
		disable_intro = true
		disable_request_login_url = true
		disable_crash_service = true

#if ALPHA
		capabilitiesGroup = "group.com.viseven.ionos.easystorage"
#elseif BETA
		capabilitiesGroup = "group.de.strato.ionos.easystorage.beta"
#elseif APPSTORE
		capabilitiesGroup = "group.com.ionos.hidrivenext"
#else
		capabilitiesGroup = "group.com.viseven.ionos.easystorage"
#endif
	}
}

extension NCBrandOptions {
	var acknowloedgements: String {
		"https://wl.hidrive.com/easy/0171"
	}
}

class NCBrandColorIONOS: NCBrandColor, @unchecked Sendable {
	
	static let ionosBrand = UIColor(red: 20.0 / 255.0, green: 116.0 / 255.0, blue: 196.0 / 255.0, alpha: 1.0) // BLUE IONOS : #1474C4
	
	override func getElement(account: String?) -> UIColor {
		if customer == UIColor(red: 0.0 / 255.0, green: 130.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0) { // default NC color
			return NCBrandColorIONOS.ionosBrand
		}
		return super.getElement(account: account)
	}
}

extension NCBrandColor {
	var brandElement: UIColor {
		return customer
	}
	
#if !EXTENSION || EXTENSION_SHARE
	var menuIconColor: UIColor {
		UIColor(resource: .FileMenu.icon)
	}
	
	var menuFolderIconColor: UIColor {
		UIColor(resource: .FileMenu.folderIcon)
	}
	
	var appBackgroundColor: UIColor {
		UIColor(resource: .AppBackground.main)
	}
	
	var formBackgroundColor: UIColor {
		UIColor(resource: .AppBackground.form)
	}
	
	var formRowBackgroundColor: UIColor {
		UIColor(resource: .AppBackground.formRow)
	}
	
	var formSeparatorColor: UIColor {
		UIColor(resource: .formSeparator)
	}
#endif
	
	var switchColor: UIColor {
		return UIColor { traits in
			let light = self.brandElement
			let dark = UIColor(red: 17.0 / 255.0, green: 199.0 / 255.0, blue: 230.0 / 255.0, alpha: 1.0)
			return traits.userInterfaceStyle == .dark ? dark : light
		}
	}
	
	var hudBackgroundColor: UIColor {
		UIColor(resource: .AppBackground.main)
	}
	
	var hudTextColor: UIColor {
		UIColor(resource: .ListCell.title)
	}
}
