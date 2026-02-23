//
//  File.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import Combine
import FirebaseAuth
import FirebaseCore
#if canImport(UIKit)
import UIKit
#endif
import GoogleSignIn
import AuthenticationServices



extension AuthActionsRepository {
    
    /// Initiates the Google Sign-In flow and generates a Firebase authentication credential.
    ///
    /// This method automatically attempts to locate the current active `UIWindowScene` and its
    /// root view controller to present the Google Sign-In modal interface.
    ///
    /// - Returns: A publisher that emits a Google `AuthCredential` on success, or a `FetchCredentialsError` on failure.
    internal func getGoogleCredential() -> AnyPublisher<AuthCredential, FetchCredentialsError> {
        perform { completion in
            #if canImport(UIKit)
            guard let clientID = FirebaseApp.app()?.options.clientID,
                  let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presenting = screen.windows.first?.rootViewController else {
                completion(.failure(.unknownError))
                return
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error {
                    completion(.failure(.googleSignInError(error)))
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    completion(.failure(.googleMissingIdToken(nil)))
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                completion(.success(credential))
            }
            #else
            completion(.failure(.unknownError))
            #endif
        }
    }
    
    /// Processes an Apple Sign-In payload and generates a Firebase authentication credential.
    ///
    /// This method extracts the `ASAuthorizationAppleIDCredential` from the provided payload.
    /// It requires the `currentNonce` property of the repository to be set prior to the Apple Sign-In
    /// request to verify the integrity of the authentication.
    ///
    /// - Parameter payload: The ``AppleAuthPayload`` containing the result of the Apple Sign-In authorization.
    /// - Returns: A publisher that emits an Apple `AuthCredential` on success, or a `FetchCredentialsError` on failure.
    internal func getAppleAuthCredential(with payload: AppleAuthPayload) -> AnyPublisher<AuthCredential, FetchCredentialsError> {
        perform { [weak self] completion in
            switch payload.result {
            case .success(let authResults):
                switch authResults.credential {
                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                    guard let nonce = self?.currentNonce,
                          let appleIDToken = appleIDCredential.identityToken else {
                        completion(.failure(.appleResultCredentialError(nil)))
                        return
                    }
                    
                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        completion(.failure(.appleSerializationError(nil)))
                        return
                    }
                    
                    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: nil)
                    
                    completion(.success(credential))
                default:
                    completion(.failure(.appleResultCredentialError(nil)))
                }
            case .failure(let error):
                completion(.failure(.appleResultError(error)))
            }
        }
    }
    
    /// Creates a Firebase authentication credential using an email and password.
    ///
    /// - Parameter payload: The ``EmailAuthPayload`` containing the user's email address and password.
    /// - Returns: A publisher that emits an Email/Password `AuthCredential` on success, or a `FetchCredentialsError` on failure.
    internal func getEmailCredential(with payload: EmailAuthPayload) -> AnyPublisher<AuthCredential, FetchCredentialsError> {
        perform { completion in
            let credential = EmailAuthProvider.credential(withEmail: payload.email, password: payload.password)
            completion(.success(credential))
        }
    }
}
