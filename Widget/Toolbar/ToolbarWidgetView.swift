// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 STRATO GmbH
// SPDX-FileCopyrightText: 2022 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import WidgetKit

struct ToolbarWidgetView: View {
    var entry: ToolbarDataEntry

    @ViewBuilder
    var body: some View {
        mainContent
            .containerBackground(Color(.background), for: .widget)
    }

    private var mainContent: some View {
        let parameterLink = "&user=\(entry.userId)&url=\(entry.url)"
        let linkNoAction: URL = URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionNoAction + parameterLink)! : URL(string: NCGlobal.shared.widgetActionNoAction)!
        let linkActionUploadAsset: URL = URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionUploadAsset + parameterLink)! : URL(string: NCGlobal.shared.widgetActionUploadAsset)!
        let linkActionScanDocument: URL = URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionScanDocument + parameterLink)! : URL(string: NCGlobal.shared.widgetActionScanDocument)!
        let linkActionVoiceMemo: URL = URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink) != nil ? URL(string: NCGlobal.shared.widgetActionVoiceMemo + parameterLink)! : URL(string: NCGlobal.shared.widgetActionVoiceMemo)!

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
					let height: CGFloat = 60
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
                            .font(Font.system(.body).weight(.light))
                            .foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(.text))
                            .background(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.brandElement))
                            .clipShape(Circle())
                            .scaledToFit()
                            .frame(width: width, height: height)
                    })

					Link(destination: entry.isPlaceholder ? linkNoAction : linkActionVoiceMemo, label: {
						Image(uiImage: UIImage(resource: .mic))
							.resizable()
							.foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(.text))
							.background(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.brandElement))
							.clipShape(Circle())
							.scaledToFit()
							.frame(width: width, height: height)
					})
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
				.padding(.vertical, geo.size.height / 2 * -0.25)
                .redacted(reason: entry.isPlaceholder ? .placeholder : [])

                HStack {
                    Image(systemName: entry.footerImage)
                        .resizable()
                        .font(Font.system(.body).weight(.light))
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.getElement(account: entry.account)))

                    Text(entry.footerText)
                        .font(.caption2)
                        .padding(.trailing, 13.0)
                        .foregroundColor(entry.isPlaceholder ? Color(.systemGray4) : Color(NCBrandColor.shared.getElement(account: entry.account)))
                }
            }
        }
        .widgetBackground(Color(.background))
    }
}

struct ToolbarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = ToolbarDataEntry(date: Date(), isPlaceholder: false, userId: "", url: "", account: "", footerImage: "Cloud_Checkmark", footerText: NCBrandOptions.shared.brand + " toolbar")
        ToolbarWidgetView(entry: entry).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
