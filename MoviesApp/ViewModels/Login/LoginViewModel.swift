import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    private let authStore: AuthStore

    var username: String = ""
    var password: String = ""
    var isPasswordVisible: Bool = false
    var errorMessage: String?
    // Mientras TMDB responde se desactivan los botones y se muestra un indicador
    private(set) var isLoading: Bool = false

    init(authStore: AuthStore) {
        self.authStore = authStore
    }

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Valida que los campos no estén vacíos y luego pide a TMDB que revise el usuario y la contraseña.
    // La contraseña no se recorta: un espacio puede ser parte de ella.
    func login() async {
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Escribe tu usuario y tu contraseña de TMDB."
            return
        }

        await run {
            try await self.authStore.login(username: self.trimmedUsername, password: self.password)
        }
    }

    // Botón "Entrar como invitado": no pide cuenta de TMDB
    func loginAsGuest() async {
        await run {
            try await self.authStore.loginAsGuest()
        }
    }

    private func run(_ action: () async throws -> Void) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await action()
            password = ""
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
