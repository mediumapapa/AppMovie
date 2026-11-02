//
//  movies_appApp.swift
//  movies_app
//
//  Created by Alberto Ávila Aguilar on 18/09/26.
//

import SwiftUI
import SwiftData

@main
struct movies_appApp: App {
    // Contenedor de SwiftData. Guarda los favoritos en el teléfono para que sigan ahí al volver a abrir la app.
    private let modelContainer: ModelContainer

    // Estado compartido de la app (sesión y favoritos)
    @State private var authStore = AuthStore()
    @State private var favoritesStore: FavoritesStore

    private let movieService: MovieServiceProtocol = MockMovieService()

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: FavoriteMovie.self)
        } catch {
            fatalError("No se pudo crear el contenedor de SwiftData: \(error)")
        }

        modelContainer = container
        _favoritesStore = State(initialValue: FavoritesStore(service: FavoritesService(container: container)))
    }

    var body: some Scene {
        WindowGroup {
            if authStore.isLoggedIn {
                NavigationStack {
                    HomeView(
                        viewModel: HomeViewModel(
                            authStore: authStore,
                            favoritesStore: favoritesStore,
                            service: movieService
                        )
                    )
                }
            } else {
                LoginView(viewModel: LoginViewModel(authStore: authStore))
            }
        }
        // Deja el contenedor en el entorno de SwiftUI por si más adelante alguna vista usa @Query
        .modelContainer(modelContainer)
    }
}
