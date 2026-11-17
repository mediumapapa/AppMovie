import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    // Para pasar del campo de usuario al de contraseña con el teclado
    private enum Field {
        case username
        case password
    }
    @FocusState private var focusedField: Field?

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
                    Spacer(minLength: 32)

                    // Ícono de Película
                    Image(systemName: "film.stack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.black)
                        .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text("Iniciar sesión")
                            .font(.system(.title, design: .rounded).weight(.heavy))
                            .foregroundColor(.black)
                            .accessibilityAddTraits(.isHeader)

                        Text("Usa tu cuenta de The Movie Database (TMDB)")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        // Campo de usuario de TMDB
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Usuario de TMDB")

                            TextField("Ingresa tu usuario", text: $viewModel.username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                                .focused($focusedField, equals: .username)
                                .onSubmit { focusedField = .password }
                                .borderedField(height: 48)
                        }

                        // Campo de Contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Contraseña")

                            HStack {
                                Group {
                                    if viewModel.isPasswordVisible {
                                        TextField("Ingresa tu contraseña", text: $viewModel.password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Ingresa tu contraseña", text: $viewModel.password)
                                    }
                                }
                                .textContentType(.password)
                                .submitLabel(.go)
                                .focused($focusedField, equals: .password)
                                .onSubmit(login)

                                Button(action: viewModel.togglePasswordVisibility) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.black.opacity(0.7))
                                }
                                .accessibilityLabel(viewModel.isPasswordVisible ? "Ocultar contraseña" : "Mostrar contraseña")
                            }
                            .borderedField(height: 48)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Mensaje de Error si falla la validación o TMDB rechaza los datos
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Botón "Ingresar"
                    Button(action: login) {
                        HStack(spacing: 10) {
                            if viewModel.isLoading {
                                ProgressView()
                            }
                            Text(viewModel.isLoading ? "Conectando con TMDB…" : "Ingresar")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.appCyan)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black, lineWidth: 1.8)
                        )
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Botón "Entrar como invitado": para explorar sin cuenta de TMDB
                    VStack(spacing: 6) {
                        Button {
                            focusedField = nil
                            Task {
                                await viewModel.loginAsGuest()
                            }
                        } label: {
                            Text("Entrar como invitado")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.black, lineWidth: 1.8)
                                )
                        }
                        .disabled(viewModel.isLoading)

                        Text("Sin cuenta también puedes buscar películas y guardar favoritos y listas en este teléfono.")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    // Enlaces externos de TMDB
                    VStack(spacing: 12) {
                        Link("¿Olvidaste tu contraseña?", destination: AppLinks.resetPassword)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.blue)

                        Link("¿No tienes cuenta? Regístrate", destination: AppLinks.signUp)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func login() {
        focusedField = nil
        Task {
            await viewModel.login()
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.black)
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(authStore: AuthStore()))
}
