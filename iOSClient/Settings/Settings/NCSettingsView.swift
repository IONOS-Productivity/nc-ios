// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2024 Aditya Tyagi
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import NextcloudKit

/// Settings view for Nextcloud
struct NCSettingsView: View {
    // State to control the visibility of the acknowledgements view
    @State private var showAcknowledgements = false
    // State to control the visibility of the passcode view
    @State private var showPasscode = false
    // State to contorl the visibility of the change passcode view
    @State private var showChangePasscode = false
    // State to control the visibility of the Policy view
    @State private var showBrowser = false
    // State to control the visibility of the Source Code  view
    @State private var showSourceCode = false
    // Object of ViewModel of this view
    @ObservedObject var model: NCSettingsModel

    var capabilities: NKCapabilities.Capabilities {
        NCNetworking.shared.capabilities[model.controller?.account ?? ""] ?? NKCapabilities.Capabilities()
    }

    var body: some View {
        Form {
            // `Auto Upload` Section
            Section(content: {
                NavigationLink(destination: LazyView {
                    NCAutoUploadView(model: NCAutoUploadModel(controller: model.controller), albumModel: AlbumModel(controller: model.controller))
                }) {
                    HStack {
                        Image(.Settings.camera)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_settings_autoupload_", comment: ""))
                    }
                }
            })
            .listRowBackground(Color(NCBrandColor.shared.formRowBackgroundColor))
            /// `Privacy` Section
            Section(content: {
                Button(action: {
                    showPasscode.toggle()
                }, label: {
                    HStack {
						lockImage(isLocked: model.isLockActive)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                            .frame(width: 20, height: 20)
                            .opacity(NCBrandOptions.shared.enforce_passcode_lock ? 0.5 : 1)
                        Text(model.isLockActive ? NSLocalizedString("_lock_active_", comment: "") : NSLocalizedString("_lock_not_active_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                /// Enable Touch ID
                Toggle(NSLocalizedString("_enable_touch_face_id_", comment: ""), isOn: $model.enableTouchID)
                    .tint(Color(NCBrandColor.shared.switchColor))
                    .onChange(of: model.enableTouchID) { _ in
                        model.updateTouchIDSetting()
                    }
                /// Reset app wrong attempts
                Toggle(NSLocalizedString("_reset_wrong_passcode_", comment: ""), isOn: $model.resetWrongAttempts)
                    .tint(Color(NCBrandColor.shared.switchColor))
                    .onChange(of: model.resetWrongAttempts) { _ in
                        model.updateResetWrongAttemptsSetting()
                    }
            }, header: {
                Text(NSLocalizedString("_privacy_", comment: "")).listRowBackground(Color.clear)
            }, footer: {
                Text(String(format: NSLocalizedString("_reset_wrong_passcode_desc_", comment: ""), NCBrandOptions.shared.resetAppPasscodeAttempts))
                    .listRowBackground(Color.clear)
                    .lineSpacing(1)
            }).applyGlobalFormSectionStyle()
            /// Calender & Contacts
            if !NCBrandOptions.shared.disable_mobileconfig {
                Section(content: {
                    Button(action: {
                        model.getConfigFiles()
                    }, label: {
                        HStack {
							Image(.Settings.calendarUser)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 23, height: 20)
                                .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                            Text(NSLocalizedString("_mobile_config_", comment: ""))
                        }
                    })
                    .tint(Color(NCBrandColor.shared.textColor))
                }, header: {
                    Text(NSLocalizedString("_calendar_contacts_", comment: ""))
                }, footer: {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("_calendar_contacts_footer_warning_", comment: ""))
                        Spacer()
                        Text(NSLocalizedString("_calendar_contacts_footer_", comment: ""))
                    }.listRowBackground(Color.clear)

                }).applyGlobalFormSectionStyle()
            }
            // `Advanced` Section
            Section {
                NavigationLink(destination: LazyView {
                    NCSettingsAdvancedView(model: NCSettingsAdvancedModel(controller: model.controller), showExitAlert: false, showCacheAlert: false)
                }) {
                    HStack {
						Image(.Settings.gear)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_advanced_", comment: ""))
                    }
                }
                
                NavigationLink(destination: LazyView {
                    DataProtectionSettingsScreen(model: DataProtectionModel(showFromSettings: true), isShowing: .constant(true))
                }) {
                    HStack {
                        Image(.Settings.dataprivacy)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_data_protection_", comment: ""))
                    }
                }
            }.applyGlobalFormSectionStyle()
            /// `Information` Section
            Section(header: Text(NSLocalizedString("_information_", comment: "")), content: {
                // Acknowledgements
                Button(action: {
                    showAcknowledgements.toggle()
                }, label: {
                    HStack {
						Image(.Settings.handshake)
                            .resizable()
							.scaledToFit()
                            .frame(width: 25, height: 20)
							.foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_acknowledgements_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .sheet(isPresented: $showAcknowledgements) {
                    NCBrowserWebView(urlBase: URL(string: NCBrandOptions.shared.acknowloedgements)!, browserTitle: NSLocalizedString("_acknowledgements_", comment: ""))
                        .ignoresSafeArea()
                }
                // Terms & Privacy Conditions
                Button(action: {
                    showBrowser.toggle()
                }, label: {
                    HStack {
						Image(.Settings.shieldHalved)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_privacy_legal_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .sheet(isPresented: $showBrowser) {
                    NCBrowserWebView(urlBase: URL(string: NCBrandOptions.shared.privacy)!, browserTitle: NSLocalizedString("_privacy_legal_", comment: ""))
                        .ignoresSafeArea()
                }
                /// Source Code
                Button(action: {
                    showSourceCode.toggle()
                }, label: {
                    HStack {
						Image(.Settings.github)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        Text(NSLocalizedString("_source_code_", comment: ""))
                    }
                })
                .tint(Color(NCBrandColor.shared.textColor))
                .sheet(isPresented: $showSourceCode) {
                    NCBrowserWebView(urlBase: URL(string: NCBrandOptions.shared.sourceCode)!, browserTitle: NSLocalizedString("_source_code_", comment: ""))
                }
            }).applyGlobalFormSectionStyle()
            /// `Watermark` Section
            Section(content: {
            }, footer: {
                Text(model.footerApp).listRowBackground(Color.clear)
            }).applyGlobalFormSectionStyle()
        }
        .sheet(isPresented: $showPasscode) {
            SetupPasscodeView(isLockActive: $model.isLockActive)
        }
        .sheet(isPresented: $showChangePasscode) {
            SetupPasscodeView(isLockActive: $model.isLockActive, changePasscode: true)
        }
        .navigationBarTitle(NSLocalizedString("_settings_", comment: ""))
		.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						Button(action: {
							model.dismiss()
						}, label: {
							Text(NSLocalizedString("_close_", comment: ""))
								.foregroundStyle(Color(NCBrandColor.shared.iconImageColor))
						})
					}
				}
        .defaultViewModifier(model)
        .applyGlobalFormStyle()
    }
	
	private func lockImage(isLocked: Bool) -> Image {
		isLocked ? Image(.itemLock) : Image(.itemLockOpen)
	}
}

struct E2EESection: View {
    @ObservedObject var model: NCSettingsModel

    var body: some View {
        Section(header: Text(NSLocalizedString("_e2e_settings_title_", comment: "")), content: {
            NavigationLink(destination: LazyView {
                NCManageE2EEView(model: NCManageE2EE(controller: model.controller))
            }) {
                HStack {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                    Text(NSLocalizedString("_e2e_settings_", comment: ""))
                }
            }
        })
    }
}

#Preview {
    NCSettingsView(model: NCSettingsModel(controller: nil))
}
