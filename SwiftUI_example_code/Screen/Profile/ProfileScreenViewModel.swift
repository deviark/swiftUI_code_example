//
//  ProfileScreenViewModel.swift
//  ScanIt
//
//  Created by Denys Hryshyn on 17.01.2024.
//

import Foundation

class ProfileScreenViewModel: ObservableObject {
    @Injected(\.loginManager) var loginManager
    @Injected(\.appleSignInService) var appleSignInAuthService
    
    @Published var networkMonitor = NetworkMonitor()
    
    @Published var userName: String = ""
    
    @Published var showAlert = false
    @Published var activeAlertSheet: ProfileActiveAlertSheet = .logout
    
    // Error properties
    @Published var errorMessage: String = ""
    
    init() {
        Logger.print("init:\(#file)")
    }
    
    deinit {
        Logger.print("deinit:\(#file)")
    }

    func setup() {
        self.userName = Settings.shared.userNameStored
    }
    
    func logout() {
        self.loginManager.service.logOutUserCall()
        self.appleSignInAuthService.googleSignOut()
    }
    
    func deleteAccount() {
        Task {
            do {
                try await loginManager.service.deleteAccount()
            } catch {
                print("DELETE ACCOUNT ERROR: \(error)")
                await setError(error)
            }
        }
    }
    
    //MARK: Displaying erros via alerts
    func setError(_ error: Error) async {
        //MARK: UI must be updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showAlert.toggle()
        })
    }
}
