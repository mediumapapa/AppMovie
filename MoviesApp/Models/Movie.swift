import SwiftUI

// Define la estructura Movie q representa una película con sus propiedades
// Posiblemente se agregue más propiedades en el futuro, como fecha de lanzamiento, calificación, etc.
// Hashable permite usar la película como valor en NavigationLink(value:)
struct Movie: Identifiable, Hashable {
    // Id de la película en TMDB. Antes era un UUID() que cambiaba cada vez que se abría la app;
    // con el id de TMDB la misma película se reconoce siempre, también en los favoritos guardados.
    let id: Int
    let title: String
    let overview: String
    // Ruta del póster en TMDB, por ejemplo "/oBvINgU5r10WHvG6VSopCOlWtJP.jpg". Vacía si no tiene póster.
    let posterPath: String

    // Dirección completa de la imagen del póster (w500 = 500 px de ancho).
    // Si la ruta no empieza con "/" (no tiene póster) regresa nil y la tarjeta muestra un ícono.
    var posterURL: URL? {
        guard posterPath.hasPrefix("/") else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500" + posterPath)
    }
}
