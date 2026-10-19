//
//  movies_appApp.swift
//  movies_app
//
//  Created by Alberto Ávila Aguilar on 18/09/26.
//

import SwiftUI

@main
struct movies_appApp: App {
    // Estado compartido de la app (sesión y favoritos)
    @State private var authStore = AuthStore()
    @State private var favoritesStore = FavoritesStore()

    private let movieService: MovieServiceProtocol = MockMovieService()

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
    }
}
