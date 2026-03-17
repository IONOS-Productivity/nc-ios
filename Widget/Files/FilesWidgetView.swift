// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 STRATO GmbH
// SPDX-FileCopyrightText: 2022 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import WidgetKit

struct FilesWidgetView: View {
    var entry: FilesDataEntry
    var body: some View {
        let parameterLink = "&user=\(entry.userId)&url=\(entry.url)"
        let linkNoAction: URL = URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink)! : URL(string: NCGlobal.shared.widgetActionNoAction)!
        let linkActionUploadAsset: URL = URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink)! : URL(string: NCGlobal.shared.widgetActionUploadAsset)!
        let linkActionScanDocument: URL = URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink)! : URL(string: NCGlobal.shared.widgetActionScanDocument)!
        let linkActionTextDocument: URL = URL(string: NCGlobal.shared.widgetActionTextDocument + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionTextDocument + parameterLink)! : URL(string: NCGlobal.shared.widgetActionTextDocument)!
        let linkActionVoiceMemo: URL = URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink)! : URL(string: NCGlobal.shared.widgetActionVoiceMemo)!

        GeometryReader { geo in
            if entry.isEmpty {
                VStack(alignment: .center) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .font(Font.system(.body).weight(.light))
                        .frame(width: 50, height: 50)
                    Text(NSLocalizedString("_no_items_", comment: ""))
                        .font(.system(size: 25))
                        .padding()
                    Text(NSLocalizedString("_check_back_later_", comment: ""))
                        .font(.system(size: 15))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            ZStack(alignment: .topLeading) {
                HStack {
                    Text(entry.tile)
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }
                .frame(width: geo.size.width - 20)
                .padding([.top, .leading, .trailing], 10)

                if !entry.isEmpty {
                    VStack(alignment: .leading) {
                        VStack(spacing: 0) {
                            ForEach(entry.datas, id: \.id) { element in
                                Link(destination: element.url) {
                                    HStack(spacing: 10) {
                                        Group {
                                            if element.useTypeIconFile {
                                                Image(uiImage: element.image)
                                                    .resizable()
                                                    .renderingMode(.template)
                                                    .foregroundColor(Color(NCBrandColor.shared.iconImageColor2))
                                                    .scaledToFit()
                                                    .frame(width: 35, height: 35)
                                            } else {
                                                Image(uiImage: element.image)
                                                    .resizable()
                                                    .frame(width: 35, height: 35)
                                                    .background(Color(.secondarySystemBackground))
                                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(element.title)
                                                .font(.system(size: 12))
    }
}

fileprivate struct WidgetContentView: View {
	let entry: FilesDataEntry
	
	var body: some View {
		VStack(alignment: .leading) {
			VStack(spacing: 0) {
				ForEach(entry.datas, id: \.id) { element in
					Link(destination: element.url) {
						HStack {
							if element.useTypeIconFile {
								Image(uiImage: element.image)
									.resizable()
									.renderingMode(.template)
									.foregroundStyle(Color(element.color ?? NCBrandColor.shared.iconImageColor))
									.scaledToFit()
									.aspectRatio(1.1, contentMode: .fit)
									.frame(width: WidgetConstants.elementIconWidthHeight,
										   height: WidgetConstants.elementIconWidthHeight)
							} else {
								Image(uiImage: element.image)
									.resizable()
									.scaledToFill()
									.frame(width: WidgetConstants.elementIconWidthHeight,
										   height: WidgetConstants.elementIconWidthHeight)
									.clipped()
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(element.title)
									.font(WidgetConstants.elementTileFont)
                                    .foregroundStyle(Color(.title))
								Text(element.subTitle)
									.font(WidgetConstants.elementSubtitleFont)
                                    .foregroundStyle(Color(.subtitle))
							}
							Spacer()
						}
						.padding(.leading, 10)
						.frame(maxHeight: .infinity)
					}
					if element != entry.datas.last {
						Divider()
                            .overlay(Color(.divider))
					}
				}
			}
		}
	}
}

struct LinkActionsToolbarView: View {
	let entry: FilesDataEntry
	let geo: GeometryProxy
	
	var body: some View {
		let parameterLink = "&user=\(entry.userId)&url=\(entry.url)"
		
		let linkNoAction: URL = URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink)! : URL(string: NCGlobal.shared.widgetActionNoAction)!
		let linkActionUploadAsset: URL = URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink)! : URL(string: NCGlobal.shared.widgetActionUploadAsset)!
		let linkActionScanDocument: URL = URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink)! : URL(string: NCGlobal.shared.widgetActionScanDocument)!
		let linkActionVoiceMemo: URL = URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink)! : URL(string: NCGlobal.shared.widgetActionVoiceMemo)!
		
		HStack(spacing: -6) {
            
			let height: CGFloat = 48
			let width = geo.size.width / 3
									
			Link(destination: entry.isPlaceholder ? linkNoAction : linkActionUploadAsset, label: {
				Image(uiImage: UIImage(resource: .media))
					.resizable()
					.renderingMode(.template)
                    .foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(.text))
					.background(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.brandElement))
					.clipShape(Circle())
					.scaledToFit()
					.frame(width: width, height: height)
			})
			
			Link(destination: entry.isPlaceholder ? linkNoAction : linkActionScanDocument, label: {
				Image(uiImage: UIImage(resource: .scan))
					.resizable()
					.renderingMode(.template)
					.foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(.text))
                    .background(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.brandElement))
					.clipShape(Circle())
					.scaledToFit()
					.font(Font.system(.body).weight(.light))
					.frame(width: width, height: height)
			})
			
			Link(destination: entry.isPlaceholder ? linkNoAction : linkActionVoiceMemo, label: {
				Image(uiImage: UIImage(resource: .mic))
					.resizable()
					.renderingMode(.template)
					.foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(.text))
					.background(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.brandElement))
					.clipShape(Circle())
					.scaledToFit()
					.frame(width: width, height: height)
			})
		}
	}
}

struct FilesWidget_Previews: PreviewProvider {
    static var previews: some View {
        let datas = Array(filesDatasTest[0...4])
        let entry = FilesDataEntry(date: Date(), datas: datas, isPlaceholder: false, isEmpty: false, userId: "", url: "", account: "", tile: "Good afternoon, Marino Faggiana", footerImage: "checkmark.icloud", footerText: "Nextcloud files")
        FilesWidgetView(entry: entry).previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
