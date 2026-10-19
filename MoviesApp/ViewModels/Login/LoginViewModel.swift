import Foundation
import Observation

@Observable
final class LoginViewModel {
    private let authStore: AuthStore

    var username: String = ""
    var password: String = ""
    var isPasswordVisible: Bool = false
    var errorMessage: String?

    init(authStore: AuthStore) {
        self.authStore = authStore
    }

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    // Valida los campos con AuthStore y muestra el error si falla
    func login() {
        let success = authStore.login(username: username, password: password)
        errorMessage = success ? nil : "Usuario o contraseña inválidos. Por favor completa ambos campos."
    }
}
