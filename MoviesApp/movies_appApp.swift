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
    // Se conserva aquí mientras la app está abierta; a FavoritesService solo se le pasa su contexto.
    private let modelContainer: ModelContainer

    // Estado compartido de la app (sesión)
    @State private var authStore = AuthStore()

    // Películas reales de TMDB. Los previews y las pruebas usan MockMovieService.
    private let movieService: MovieServiceProtocol = MovieService()
    private let favoritesService: FavoritesServiceProtocol

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: FavoriteMovie.self)
        } catch {
            fatalError("No se pudo crear el contenedor de SwiftData: \(error)")
        }

        modelContainer = container
        favoritesService = FavoritesService(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            if authStore.isLoggedIn {
                NavigationStack {
                    HomeView(
                        viewModel: HomeViewModel(
                            authStore: authStore,
                            movieService: movieService,
                            favoritesService: favoritesService
                        )
                    )
                }
            } else {
                LoginView(viewModel: LoginViewModel(authStore: authStore))
            }
        }
    }
}
