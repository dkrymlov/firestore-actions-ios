//
//  File.swift
//  FirebaseActions
//
//  Created by Данило Кримлов on 22.02.2026.
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import FirebaseCore

/// A typealias representing a Firebase user.
public typealias FirebaseUser = FirebaseAuth.User

/// A repository protocol defining standard Firebase Authentication operations.
///
/// `AuthActionsRepositoryType` provides a reactive interface using Combine publishers
/// to handle user authentication, account management, and credential linking.
public protocol AuthActionsRepositoryType {
    
    /// The type representing supported authentication providers (e.g., Apple, Google, Email).
    associatedtype FirebaseAuthProvider
    
    /// Registers a new user using the provided email payload.
    ///
    /// - Parameter emailAuthPayload: The payload containing the email and password for registration.
    /// - Returns: A publisher that emits the newly created `FirebaseUser` on success, or a `SignUpError` on failure.
    func signUp(_ emailAuthPayload: EmailAuthPayload) -> AnyPublisher<FirebaseUser, SignUpError>
    
    /// Authenticates a user using an existing Firebase authentication credential.
    ///
    /// - Parameter authCredential: The credential to sign in with (e.g., from Google, Apple, or Email/Password).
    /// - Returns: A publisher that emits the authenticated `FirebaseUser` on success, or a `SignInError` on failure.
    func signIn(with authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, SignInError>
    
    /// Authenticates a user anonymously.
    ///
    /// - Returns: A publisher that emits the anonymous `FirebaseUser` on success, or a `SignInError` on failure.
    func signInAnnonymously() -> AnyPublisher<FirebaseUser, SignInError>
    
    /// Links a new authentication credential to an existing user account.
    ///
    /// This is typically used to upgrade an anonymous account to a permanent one by linking it with an email or third-party provider.
    ///
    /// - Parameters:
    ///   - authUser: The current `FirebaseUser` to which the credential will be linked.
    ///   - authCredential: The new credential to link to the user's account.
    /// - Returns: A publisher that emits the updated `FirebaseUser` on success, or a `SignInError` on failure.
    func linkIn(authUser: FirebaseUser, with authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, SignInError>
    
    /// Sends a password reset email to the specified email address.
    ///
    /// - Parameter email: The email address associated with the user's account.
    /// - Returns: A publisher that emits `Void` upon successfully sending the email, or a `ResetPasswordError` on failure.
    func resetPassword(for email: String) -> AnyPublisher<Void, ResetPasswordError>
    
    /// Signs out the currently authenticated user.
    ///
    /// - Returns: A publisher that emits `Void` on successful sign out, or a `SignOutError` on failure.
    func signOut() -> AnyPublisher<Void, SignOutError>
    
    /// Deletes the specified user account from Firebase.
    ///
    /// - Warning: This is a destructive action. The user may need to be recently authenticated to perform this operation.
    /// If the user's last sign-in is too old, this may fail and require `reauthenticate(authUser:authCredential:)`.
    ///
    /// - Parameter authUser: The `FirebaseUser` account to delete.
    /// - Returns: A publisher that emits `Void` on successful deletion, or a `DeleteAccountError` on failure.
    func deleteAccount(authUser: FirebaseUser) -> AnyPublisher<Void, DeleteAccountError>
    
    /// Sends a verification email to the user.
    ///
    /// - Parameter authUser: The `FirebaseUser` who should receive the verification email.
    /// - Returns: A publisher that emits `Void` when the email is sent, or an `EmailVerificationError` on failure.
    func sendEmailVerification(authUser: FirebaseUser) -> AnyPublisher<Void, EmailVerificationError>
    
    /// Re-authenticates a user with a given credential.
    ///
    /// This is required for sensitive operations like changing a password, updating an email, or deleting an account
    /// when the user's login session has expired.
    ///
    /// - Parameters:
    ///   - authUser: The current `FirebaseUser` to re-authenticate.
    ///   - authCredential: The credential to verify the user's identity.
    /// - Returns: A publisher that emits the re-authenticated `FirebaseUser` on success, or a `ReauthenticateError` on failure.
    func reauthenticate(authUser: FirebaseUser, authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, ReauthenticateError>
    
    /// Generates an `AuthCredential` for a specific authentication provider.
    ///
    /// - Parameter authProvider: The provider (e.g., Apple, Google) to generate the credential for.
    /// - Returns: A publisher that emits the generated `AuthCredential` on success, or a `FetchCredentialsError` on failure.
    func getAuthCredential(for authProvider: FirebaseAuthProvider) -> AnyPublisher<AuthCredential, FetchCredentialsError>
}

/// A concrete implementation of ``AuthActionsRepositoryType`` that interacts directly with Firebase Authentication.
///
/// This repository provides the actual implementation for authenticating users, managing accounts,
/// and generating credentials. It utilizes a private Combine wrapper to convert standard asynchronous
/// Firebase callbacks into Combine publishers for a reactive workflow.
public final class AuthActionsRepository: AuthActionsRepositoryType {
    
    /// A cryptographic nonce used to prevent replay attacks, primarily during Apple Sign-In.
    internal var currentNonce: String?
    
    /// Defines the supported Firebase authentication providers and their required payloads.
    public enum FirebaseAuthProvider {
        /// Email and password authentication provider.
        case email(payload: EmailAuthPayload)
        /// Apple Sign-In authentication provider.
        case apple(payload: AppleAuthPayload)
        /// Google Sign-In authentication provider.
        case google
    }
    
    /// Initializes a new instance of the authentication repository.
    public init() {}
    
    // MARK: - Generics Wrapper
    
    /// A private helper that wraps asynchronous Firebase Auth callbacks into a Combine `Future`.
    ///
    /// This method standardizes the creation of publishers across the repository, reducing boilerplate
    /// code when handling success and failure states from Firebase.
    ///
    /// - Parameter action: A closure that provides a result handler for the Firebase operation.
    /// - Returns: An `AnyPublisher` that emits the generic type `T` on success or an `Error` on failure.
    internal func perform<T, E: Error>(_ action: @escaping (@escaping (Result<T, E>) -> Void) -> Void) -> AnyPublisher<T, E> {
        Future<T, E> { promise in
            action { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: Auth
    
    /// Re-authenticates the user using the provided credentials.
    ///
    /// - Parameters:
    ///   - authUser: The current `FirebaseUser` object.
    ///   - authCredential: The credential to verify the user's identity.
    /// - Returns: A publisher emitting the re-authenticated user or a `ReauthenticateError`.
    public func reauthenticate(authUser: FirebaseUser, authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, ReauthenticateError> {
        perform { completion in
            authUser.reauthenticate(with: authCredential) { result, error in
                if let error {
                    completion(.failure(.reauthenticateError(error)))
                }
                
                if let user = result?.user {
                    completion(.success(user))
                } else {
                    completion(.failure(.reauthenticateError(nil)))
                }
            }
        }
    }
    
    /// Generates a Firebase `AuthCredential` based on the specified provider.
    ///
    /// - Parameter authProvider: The ``FirebaseAuthProvider`` detailing the sign-in method and associated payload.
    /// - Returns: A publisher emitting the generated `AuthCredential` or a `FetchCredentialsError`.
    public func getAuthCredential(for authProvider: FirebaseAuthProvider) -> AnyPublisher<AuthCredential, FetchCredentialsError> {
        switch authProvider {
        case .email(let payload):
            return self.getEmailCredential(with: payload)
        case .apple(let payload):
            return self.getAppleAuthCredential(with: payload)
        case .google:
            return self.getGoogleCredential()
        }
    }
    
    /// Creates a new user account using an email and password.
    ///
    /// - Parameter emailAuthPayload: The payload containing the email and password.
    /// - Returns: A publisher emitting the newly created `User` or a `SignUpError`.
    public func signUp(_ emailAuthPayload: EmailAuthPayload) -> AnyPublisher<User, SignUpError> {
        perform { completion in
            Auth.auth().createUser(
                withEmail: emailAuthPayload.email,
                password: emailAuthPayload.password
            ) { authResult, error in
                if let error {
                    completion(.failure(.signUpError(error)))
                }
                
                guard let authUser = authResult?.user else {
                    completion(.failure(.signUpError(nil)))
                    return
                }
                
                completion(.success(authUser))
            }
        }
    }
    
    /// Signs in a user using a previously generated authentication credential.
    ///
    /// - Parameter authCredential: The Firebase `AuthCredential` to sign in with.
    /// - Returns: A publisher emitting the signed-in `FirebaseUser` or a `SignInError`.
    public func signIn(with authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, SignInError> {
        perform { completion in
            Auth.auth().signIn(with: authCredential) { authResult, error in
                if let error {
                    completion(.failure(.signInError(error)))
                }
                
                if let authUser = authResult?.user {
                    completion(.success(authUser))
                } else {
                    completion(.failure(.signInError(nil)))
                }
            }
        }
    }
    
    /// Links an authentication credential to an existing user account.
    ///
    /// - Parameters:
    ///   - authUser: The current `FirebaseUser` account.
    ///   - authCredential: The credential to link.
    /// - Returns: A publisher emitting the updated `FirebaseUser` or a `SignInError`.
    public func linkIn(authUser: FirebaseUser, with authCredential: AuthCredential) -> AnyPublisher<FirebaseUser, SignInError> {
        perform { completion in
            authUser.link(with: authCredential) { authResult, error in
                if let error {
                    completion(.failure(.linkInError(error)))
                }
                
                if let authUser = authResult?.user {
                    completion(.success(authUser))
                } else {
                    completion(.failure(.linkInError(nil)))
                }
            }
        }
    }
    
    /// Authenticates the user anonymously, creating a temporary account.
    ///
    /// - Returns: A publisher emitting the anonymous `FirebaseUser` or a `SignInError`.
    public func signInAnnonymously() -> AnyPublisher<FirebaseUser, SignInError> {
        perform { completion in
            Auth.auth().signInAnonymously() { authResult, error in
                if let error = error {
                    completion(.failure(.annonymousSignInError(error)))
                    return
                }
                
                guard let user = authResult?.user else {
                    completion(.failure(.annonymousSignInError(nil)))
                    return
                }
                
                completion(.success(user))
            }
        }
    }
    
    /// Sends a verification email to the currently authenticated user.
    ///
    /// - Parameter authUser: The `FirebaseUser` account that should receive the verification link.
    /// - Returns: A publisher emitting `Void` on success or an `EmailVerificationError` on failure.
    public func sendEmailVerification(authUser: FirebaseUser) -> AnyPublisher<Void, EmailVerificationError> {
        perform { completion in
            authUser.sendEmailVerification(completion: { error in
                if let error {
                    completion(.failure(.emailVerificationError(error)))
                }
                
                completion(.success(()))
            })
        }
    }
    
    /// Initiates a password reset flow for the specified email address.
    ///
    /// - Parameter email: The email address associated with the account.
    /// - Returns: A publisher emitting `Void` on success or a `ResetPasswordError` on failure.
    public func resetPassword(for email: String) -> AnyPublisher<Void, ResetPasswordError> {
        perform { completion in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    completion(.failure(.resetPasswordError(error)))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Signs out the currently active user, clearing their local session.
    ///
    /// - Returns: A publisher emitting `Void` on success or a `SignOutError` on failure.
    public func signOut() -> AnyPublisher<Void, SignOutError> {
        perform { completion in
            do {
                try Auth.auth().signOut()
                completion(.success(()))
            } catch {
                completion(.failure(.signOutError(error)))
            }
        }
    }
    
    /// Permanently deletes the user's account from Firebase.
    ///
    /// - Parameter authUser: The `FirebaseUser` account to delete.
    /// - Returns: A publisher emitting `Void` on success or a `DeleteAccountError` on failure.
    public func deleteAccount(authUser: FirebaseUser) -> AnyPublisher<Void, DeleteAccountError> {
        perform { completion in
            authUser.delete(completion: { error in
                if let error {
                    completion(.failure(.deleteAccountError(error)))
                } else {
                    completion(.success(()))
                }
            })
        }
    }
}

