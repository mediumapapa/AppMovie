import Foundation

// Datos de prueba mientras se conecta la API de TMDB
extension Movie {

    static let sampleMovies: [Movie] = [
        Movie(title: "Dune: Parte Dos", overview: "Paul Atreides se une a Chani y a los Fremen para buscar venganza.", posterPath: "popcorn.fill"),
        Movie(title: "Interstellar", overview: "Un grupo de exploradores viaja a través de un agujero de gusano en el espacio.", posterPath: "film.fill"),
        Movie(title: "Arrival", overview: "Una lingüista es reclutada para comunicarse con visitantes extraterrestres.", posterPath: "tv.fill"),
        Movie(title: "Inception", overview: "Un ladrón que roba secretos a través de los sueños recibe la tarea de implantar una idea.", posterPath: "video.fill"),
        Movie(title: "Oppenheimer", overview: "La historia del científico estadounidense y su papel en el desarrollo de la bomba atómica.", posterPath: "popcorn.fill"),
        Movie(title: "The Dark Knight", overview: "Batman se enfrenta al Joker mientras este desata el caos sobre las calles de Gotham.", posterPath: "film.fill"),
        Movie(title: "Avengers: Infinity War", overview: "Los Vengadores se unen para evitar que Thanos reúna las seis gemas del infinito.", posterPath: "tv.fill"),
        Movie(title: "The Batman", overview: "En su segundo año de lucha contra el crimen, Batman investiga la corrupción en Gotham.", posterPath: "person.crop.circle.fill"),
        Movie(title: "Blade Runner 2049", overview: "Un nuevo Blade Runner descubre un secreto que lo lleva a buscar a Rick Deckard.", posterPath: "video.fill"),
        Movie(title: "Fight Club", overview: "Un empleado con insomnio y un vendedor de jabón forman un club de lucha clandestino.", posterPath: "popcorn.fill")
    ]
}

// Servicio de prueba: regresa las películas locales
struct MockMovieService: MovieServiceProtocol {

    func popularMovies() -> [Movie] {
        Movie.sampleMovies
    }

    func movies(forGenre genre: String) -> [Movie] {
        Movie.sampleMovies
    }

    func searchMovies(matching query: String) -> [Movie] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        return Movie.sampleMovies.filter {
            $0.title.localizedCaseInsensitiveContains(text) ||
            $0.overview.localizedCaseInsensitiveContains(text)
        }
    }
}
