import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Barra Superior: solo el título, sin botones porque aún no hay sesión
            AppHeaderBar {
                AppHeaderTitle(text: "TMDB MOVIES")
                Spacer()
            }

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
                            fieldLabel("Usuario / Correo")

                            TextField("Ingresa tu usuario", text: $viewModel.username)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .borderedField()
                        }

                        // Campo de Contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Contraseña")

                            HStack {
                                if viewModel.isPasswordVisible {
                                    TextField("Ingresa tu contraseña", text: $viewModel.password)
                                        .textInputAutocapitalization(.never)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Ingresa tu contraseña", text: $viewModel.password)
                                }

                                Button(action: viewModel.togglePasswordVisibility) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .borderedField()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Mensaje de Error si falla la validación
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Botón "Ingresar"
                    Button(action: viewModel.login) {
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

                    // Enlaces externos de TMDB
                    VStack(spacing: 12) {
                        Link("¿Olvidaste tu contraseña?", destination: AppLinks.resetPassword)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)

                        Link("¿No tienes cuenta? Regístrate", destination: AppLinks.signUp)
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(authStore: AuthStore()))
}
