import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra Superior 
            headerBar
            
            // Formulario de Login
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Ícono de Película
                    Image(systemName: "film.stack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.black)
                    
                    Text("Iniciar Sesión")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading, spacing: 18) {
                        // Campo de Correo / Usuario
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Usuario / Correo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            TextField("Ingresa tu usuario", text: $username)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.black, lineWidth: 1.8)
                                )
                        }
                        
                        // Campo de Contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contraseña")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            HStack {
                                if isPasswordVisible {
                                    TextField("Ingresa tu contraseña", text: $password)
                                        .textInputAutocapitalization(.never)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Ingresa tu contraseña", text: $password)
                                }
                                
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.black, lineWidth: 1.8)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Mensaje de Error si falla la validación
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Botón "Ingresar"
                    Button(action: handleLogin) {
                        Text("Ingresar")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.appCyan)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.black, lineWidth: 1.8)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    // Enlaces de navegación externa (según README y navigation-and-state.md)
                    VStack(spacing: 12) {
                        Link("¿Olvidaste tu contraseña?", destination: URL(string: "https://www.themoviedb.org/reset-password")!)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Link("¿No tienes cuenta? Regístrate", destination: URL(string: "https://www.themoviedb.org/signup")!)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // Header Bar: solo el título, sin los botones de listas, favoritos ni cuenta
    private var headerBar: some View {
        HStack {
            Text("TMDB MOVIES")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.appCyan.ignoresSafeArea(edges: .top))
    }
    
    private func handleLogin() {
        let success = authStore.login(username: username, password: password)
        if !success {
            errorMessage = "Usuario o contraseña inválidos. Por favor completa ambos campos."
        } else {
            errorMessage = nil
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthStore())
}
