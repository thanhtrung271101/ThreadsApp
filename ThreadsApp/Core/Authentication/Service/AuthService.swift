//
//  AuthService.swift
//  ThreadsApp
//
//  Created by Thành Trung on 4/9/24.
//

import FirebaseAuth
import FirebaseFirestore

class AuthService {

    @Published var userSession: FirebaseAuth.User?

    static let shared = AuthService()

    init() {
        self.userSession = Auth.auth().currentUser
    }

    @MainActor
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            try await UserService.shared.fetchCurrentUser()
        } catch {
            print("DEBUG: Failed to login with error \(error.localizedDescription)")
        }
    }

    @MainActor
    func createUser(withEmail email: String, password: String, fullName: String, userName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            try await uploadUserData(withEmail: email, fullName: fullName, userName: userName, id: result.user.uid)
        } catch {
            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
        }
    }

    func signOut() {
        try? Auth.auth().signOut() // sign out on backend
        self.userSession = nil // this removes session locally and updates routing
        UserService.shared.reset()
    }

    @MainActor
    private func uploadUserData(
        withEmail email: String,
        fullName: String,
        userName: String,
        id: String
    ) async throws {
        let user = User(id: id, fullName: fullName, userName: userName, email: email, profileImageUrl: "", bio: "")
        guard let userData = try? Firestore.Encoder().encode(user) else { return }
        try await Firestore.firestore().collection("users").document(id).setData(userData)
    }
}
