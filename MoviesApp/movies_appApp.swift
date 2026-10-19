//
//  movies_appApp.swift
//  movies_app
//
//  Created by Alberto Ávila Aguilar on 18/09/26.
//

import SwiftUI

@main
struct movies_appApp: App {
    // Instancias de estado compartido para la aplicación
    @State private var authStore = AuthStore()
    @State private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.isLoggedIn {
                    NavigationStack {
                        ContentView()
                    }
                } else {
                    LoginView()
                }
            }
            .environment(authStore)
            .environment(favoritesStore)
        }
    }
}
