import SwiftUI

/// Almacén de estado compartido para la sesión de usuario.
/// Gestiona si el usuario ha iniciado sesión y los datos básicos de la cuenta activa.
@Observable
class AuthStore {
    var isLoggedIn: Bool = false
    var currentUser: String = ""
    
    init(isLoggedIn: Bool = false, currentUser: String = "") {
        self.isLoggedIn = isLoggedIn
        self.currentUser = currentUser
    }
    
    /// Valida e inicia sesión
    func login(username: String, password: String) -> Bool {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUser.isEmpty && !trimmedPass.isEmpty else {
            return false
        }
        
        // Simulación de sesión exitosa para el MVP
        self.currentUser = trimmedUser
        self.isLoggedIn = true
        return true
    }
    
    /// Cierra la sesión activa
    func logout() {
        self.currentUser = ""
        self.isLoggedIn = false
    }
}
