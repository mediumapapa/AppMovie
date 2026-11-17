//
//  AuthTests.swift
//  MoviesAppTests
//
//  Pruebas del inicio de sesión (LoginViewModel + AuthStore) con MockAuthService
//  e InMemorySessionStorage: no usan internet ni el Llavero.
//

import XCTest
@testable import movies_app

@MainActor
final class AuthTests: XCTestCase {

    private var storage: InMemorySessionStorage!
    private var authService: MockAuthService!

    override func setUp() {
        super.setUp()
        storage = InMemorySessionStorage()
        authService = MockAuthService(validUsername: "cinefilo", validPassword: "secreta")
    }

    private func makeStore() -> AuthStore {
        AuthStore(authService: authService, storage: storage)
    }

    // MARK: - Caso normal

    func testSuccessfulLoginOpensAndSavesSession() async {
        let store = makeStore()
        let viewModel = LoginViewModel(authStore: store)

        viewModel.username = "  cinefilo "
        viewModel.password = "secreta"
        await viewModel.login()

        XCTAssertTrue(store.isLoggedIn)
        XCTAssertEqual(store.currentUser, "cinefilo")
        XCTAssertFalse(store.isGuest)
        XCTAssertEqual(storage.session?.sessionID, "session-cinefilo")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.password, "", "La contraseña no se queda en memoria después de entrar")
    }

    func testGuestLoginDoesNotNeedAccount() async {
        let store = makeStore()
        let viewModel = LoginViewModel(authStore: store)

        await viewModel.loginAsGuest()

        XCTAssertTrue(store.isLoggedIn)
        XCTAssertTrue(store.isGuest)
        XCTAssertEqual(store.currentUser, "Invitado")
    }

    // Al volver a abrir la app, la sesión guardada se recupera y se entra directo al Home
    func testSavedSessionIsRestoredOnLaunch() {
        storage.save(UserSession(sessionID: "abc", username: "cinefilo", isGuest: false))

        let store = makeStore()

        XCTAssertTrue(store.isLoggedIn)
        XCTAssertEqual(store.currentUser, "cinefilo")
    }

    func testLogoutForgetsSession() async throws {
        let store = makeStore()
        try await store.login(username: "cinefilo", password: "secreta")

        store.logout()

        XCTAssertFalse(store.isLoggedIn)
        XCTAssertNil(storage.session)
    }

    // MARK: - Entrada inválida y errores

    func testEmptyFieldsShowMessageWithoutCallingTMDB() async {
        let store = makeStore()
        let viewModel = LoginViewModel(authStore: store)

        viewModel.username = "   "
        viewModel.password = "secreta"
        await viewModel.login()

        XCTAssertFalse(store.isLoggedIn)
        XCTAssertEqual(viewModel.errorMessage, "Escribe tu usuario y tu contraseña de TMDB.")
    }

    func testWrongPasswordShowsTMDBMessage() async {
        let store = makeStore()
        let viewModel = LoginViewModel(authStore: store)

        viewModel.username = "cinefilo"
        viewModel.password = "otra"
        await viewModel.login()

        XCTAssertFalse(store.isLoggedIn)
        XCTAssertNil(storage.session)
        XCTAssertEqual(viewModel.errorMessage, "Usuario o contraseña de TMDB incorrectos.")
        XCTAssertFalse(viewModel.isLoading)
    }

    // Si APIKeys.swift no tiene token, el mensaje dice exactamente qué archivo editar
    func testMissingTokenExplainsWhatToDo() async {
        authService.errorToThrow = .missingToken
        let viewModel = LoginViewModel(authStore: makeStore())

        await viewModel.loginAsGuest()

        XCTAssertEqual(viewModel.errorMessage, MovieServiceError.missingToken.errorDescription)
        XCTAssertTrue(viewModel.errorMessage?.contains("APIKeys.swift") ?? false)
    }
}
