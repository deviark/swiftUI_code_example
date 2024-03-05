//
//  ProfileScreen.swift
//  ScanIt
//
//  Created by Denys Hryshyn on 17.01.2024.
//

import SwiftUI
import NavigationStack

protocol ProfileScreenRouter: AnyObject {
    func goToContactSupport() -> ContactSupportScreen
    func goToEditProfile() -> EditProfileScreen
    func goToPrivacyPolicy() -> PrivacyPolicyScreen
}

struct ProfileScreen: View {
    @State var router: ProfileScreenRouter?
    @StateObject var viewModel: ProfileScreenViewModel = ProfileScreenViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Main content
                VStack(spacing: 16) {
                    PushView(destination: router?.goToContactSupport(), label: {
                        createButtonWithRightArrow(text: "Support",
                                                   iconName: "profileToolIcon",
                                                   bgColor: Color(red: 0.46, green: 0.46, blue: 0.5).opacity(0.24),
                                                   overlayColor: .white.opacity(0.3),
                                                   radius: 6)
                    })
                    
                    PushView(destination: router?.goToPrivacyPolicy(), label: {
                        createButtonWithRightArrow(text: "Datenschutzrichtlinie",
                                                   iconName: "profileLockIcon",
                                                   bgColor: Color(red: 0.46, green: 0.46, blue: 0.5).opacity(0.24),
                                                   overlayColor: .white.opacity(0.3),
                                                   radius: 6)
                    })
                    
                    Button(action: {
                        viewModel.activeAlertSheet = .notReadyFunctional
                        viewModel.showAlert.toggle()
                    }) {
                        createButtonWithRightArrow(text: "Sicherheit",
                                                   iconName: "security",
                                                   bgColor: Color(red: 0.46, green: 0.46, blue: 0.5).opacity(0.24),
                                                   overlayColor: .white.opacity(0.3),
                                                   radius: 6)
                    }
                    
                    Button(action: {
                        viewModel.activeAlertSheet = .notReadyFunctional
                        viewModel.showAlert.toggle()
                    }) {
                        createButtonWithRightArrow(text: "Zahlungsinformationen",
                                                   iconName: "credit-card",
                                                   bgColor: Color(red: 0.46, green: 0.46, blue: 0.5).opacity(0.24),
                                                   overlayColor: .white.opacity(0.3),
                                                   radius: 6)
                    }
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Bottom content
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.activeAlertSheet = .deleteAccount
                        viewModel.showAlert.toggle()
                    }) {
                        createButtonWithRightArrow(text: "Konto löschen",
                                                   iconName: "profileTrashIcon",
                                                   bgColor: .clear,
                                                   overlayColor: Color(red: 0.95, green: 0.24, blue: 0.24),
                                                   radius: 6,
                                                   showArrow: false)
                    }
                    
                    Button(action: {
                        viewModel.activeAlertSheet = .logout
                        viewModel.showAlert.toggle()
                    }) {
                        createButtonWithRightArrow(text: "Ausloggen",
                                                   iconName: "profileLogoutIcon",
                                                   bgColor: .clear,
                                                   overlayColor: Color("mainBlue"),
                                                   radius: 6,
                                                   showArrow: false)
                    }
                }
                .padding(.bottom, 45)
            }
            .padding()
            .padding(.horizontal, 16)
            
            .navigationTitle("@\(viewModel.userName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back btn
                    HStack {
                        PopView(destination: .previous) {
                            createNativeBackButton()
                        }
                        
                        Spacer()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Edit btn
                    PushView(destination: router?.goToEditProfile(), label: {
                        Image("editProfileIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color.white)
                            .frame(width: 24, height: 24)
                    })
                }
            }
            
            .onAppear {
                viewModel.setup()
            }
            
            //.overlay(NoInternetConnectionView(hide: $viewModel.networkMonitor.isConnected))
            
            .popup(isPresented: $viewModel.networkMonitor.isConnected.not, view: {
                NoInternetConnectionView()
            }, customize: {
                $0
                        .isOpaque(true)
                        .position(.center)
                        .animation(.spring())
                        .closeOnTapOutside(false)
                        .dragToDismiss(false)
                        .closeOnTap(false)
                        .backgroundColor(Color(red: 0.13, green: 0.15, blue: 0.2))
            })
            
            .alert(isPresented: $viewModel.showAlert) {
                switch self.viewModel.activeAlertSheet {
                case .deleteAccount:
                    return Alert(title: Text("Alarm"), message: Text("Sind Sie sicher, dass Sie Ihr Konto löschen möchten?"), primaryButton: .destructive(Text("Löschen"), action: { self.viewModel.deleteAccount() }), secondaryButton: .cancel())
                case .logout:
                    return Alert(title: Text("Alarm"), message: Text("Möchten Sie sich wirklich abmelden?"), primaryButton: .destructive(Text("Ausloggen"), action: { self.viewModel.logout() }), secondaryButton: .cancel())
                case .deleteAccountError:
                    return Alert(title: Text("Fehler"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("Habe es!")))
                case .notReadyFunctional:
                    return Alert(title: Text("Hoppla!"), message: Text("Leider ist diese Funktion noch nicht verfügbar."), dismissButton: .default(Text("Habe es!")))
                }
            }
        }
    }
}

struct ProfileScreenPreviews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
    }
}
