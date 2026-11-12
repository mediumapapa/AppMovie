# Práctica 7: Integración con la API de TMDB

En esta práctica el Home dejó de usar las películas de muestra. Ahora las pide a la API REST de TMDB con `URLSession`, `async/await` y modelos `Decodable`, y la pantalla muestra los estados Loading, Content, Empty y Error, con un botón para reintentar.

## Endpoints

Todos usan la URL base `https://api.themoviedb.org/3` y el parámetro `language=es-MX`.

| Endpoint | Sección del Home |
|---|---|
| `GET /trending/movie/week` (principal) | "Popular this week" |
| `GET /discover/movie?with_genres=28` | "Action" |
| `GET /discover/movie?with_genres=18` | "Drama" |

Los pósters se cargan de `https://image.tmdb.org/t/p/w500` + `poster_path`.

La autenticación usa el **Token de acceso de lectura** en el encabezado `Authorization: Bearer <token>`. El token no está en el repositorio (ver [Llave de la API](#llave-de-la-api)).

## Capas

```
HomeView                    (Views)        muestra lo que dice state; no sabe de HTTP
    ↓ .task / botón Reintentar
HomeViewModel               (ViewModels)   loadMovies() async, administra state: HomeState
    ↓
MovieServiceProtocol        (Services)     popularMovies(), movies(forGenreID:)  async throws
    ↓
MovieService                (Production)   URLSession + HTTPURLResponse + JSONDecoder
MockMovieService            (Mock)         películas de muestra para previews y pruebas
    ↓
TMDBMovieList / TMDBMovie   (Models)       forma del JSON (Decodable) → se convierte en Movie
```

Se siguió la misma organización de las prácticas anteriores: el protocolo en `Services/`, la implementación real en `Production/` y el mock en `Mock/`, como pidió el profe en la revisión del PR #9.

## Parte 1: el servicio (`Services/Production/MovieService.swift`)

`fetchMovies(path:queryItems:)` hace la consulta completa en cinco pasos:

1. **URL:** arma la dirección con `URLComponents` y sus `URLQueryItem`. Si no se puede, lanza `invalidURL`.
2. **Solicitud:** crea un `URLRequest` y pone el token en el encabezado `Authorization`.
3. **Ejecución:** `try await URLSession.shared.data(for: request)`. El `await` espera la respuesta sin bloquear la pantalla. Si falla (sin internet, tiempo agotado), lanza `noConnection`.
4. **Validación HTTP:** convierte la respuesta a `HTTPURLResponse` y revisa que `statusCode` esté entre 200 y 299. Si no, lanza `badStatus(código)`.
5. **Decodificación:** `JSONDecoder().decode(TMDBMovieList.self, from: data)` y convierte cada `TMDBMovie` en `Movie`. Si el JSON no tiene la forma esperada, lanza `decodingFailed`.

`popularMovies()` y `movies(forGenreID:)` solo llaman a `fetchMovies` con su endpoint.

### Modelos `Decodable` (`Models/TMDBMovie.swift`)

- `TMDBMovieList` tiene `results: [TMDBMovie]`. Los demás campos del JSON (`page`, `total_pages`…) se ignoran.
- `TMDBMovie` tiene `id`, `title`, `overview` y `posterPath`. `CodingKeys` traduce `poster_path` a `posterPath`. `posterPath` es opcional porque TMDB lo manda en `null` cuando no hay póster.
- `var movie: Movie` convierte la película de TMDB en el `Movie` que ya usaban las vistas, igual que `FavoriteMovie.movie`. Así las vistas no cambiaron de modelo.

### Errores (`Services/MovieServiceError.swift`)

| Error | Cuándo pasa | Mensaje |
|---|---|---|
| `invalidURL` | No se pudo armar la URL | No se pudo armar la dirección de la consulta. |
| `noConnection` | No hay internet o la solicitud no llegó | No se pudo conectar con TMDB. Revisa tu conexión a internet. |
| `invalidResponse` | La respuesta no es HTTP | TMDB regresó una respuesta que no se pudo leer. |
| `badStatus(401)` | Token inválido o faltante | TMDB rechazó el token (código 401). Revisa el archivo APIKeys.swift. |
| `badStatus(código)` | Cualquier otro código fuera de 200...299 | TMDB respondió con un error (código X). |
| `decodingFailed` | El JSON no tiene la forma esperada | No se pudieron leer las películas que mandó TMDB. |

`MovieServiceError` cumple `LocalizedError`, así que el ViewModel solo usa `error.localizedDescription` para obtener el mensaje.

## Parte 2: el ViewModel (`ViewModels/Home/HomeViewModel.swift`)

- `loadMovies() async` es la operación asíncrona. Pone `state = .loading`, pide las tres secciones una después de otra con `try await` y al final pone `.content`, `.empty` o `.error`.
- Si cualquiera de las tres consultas falla, el `catch` pone `.error(error.localizedDescription)`. El error no se esconde.
- Las secciones que llegan vacías no se muestran. Si las tres llegan vacías, el estado es `.empty`.
- `loadMoviesIfNeeded()` es lo que llama la vista al aparecer. Si ya hay películas no vuelve a consultar; así, al regresar del detalle no se recarga todo.
- `HomeViewModel` tiene `@MainActor` para que `state` siempre se actualice en el hilo principal, que es el que dibuja la pantalla. Mientras se espera la respuesta (`await`), el hilo principal queda libre.

### Una sola fuente de verdad (`ViewModels/Home/HomeState.swift`)

```swift
enum HomeState: Equatable {
    case loading
    case content([MovieSection])
    case empty
    case error(String)
}
```

Las secciones solo existen dentro de `.content`. Antes `sections` era una propiedad aparte; si se hubiera agregado `isLoading` y `errorMessage` por separado, podrían quedar combinaciones imposibles (cargando y con error al mismo tiempo). Con un solo `enum` la pantalla solo puede estar en un estado.

### Búsqueda

El buscador ahora filtra por título o sinopsis entre las películas que ya llegaron de TMDB (las de las tres secciones). Si una película viene en dos secciones, aparece una sola vez en los resultados. Se decidió así para no agregar una segunda consulta con sus propios estados en esta práctica (ver [Pendientes](#pendientes)).

## Parte 3: estados en la vista (`Views/Home/HomeView.swift`)

`HomeView` hace un `switch viewModel.state`:

| Estado | Qué se ve |
|---|---|
| Loading | `ProgressView` con el texto "Cargando películas..." |
| Content | Las secciones con sus carruseles, igual que antes, ahora con pósters reales |
| Empty | Ícono, "No hay películas por ahora" y botón **Actualizar** |
| Error | Ícono de advertencia, "No se pudieron cargar las películas", el mensaje del error y botón **Reintentar** |

- La carga empieza con `.task { await viewModel.loadMoviesIfNeeded() }`.
- Los botones Reintentar y Actualizar llaman `Task { await viewModel.loadMovies() }`.
- La vista no conoce URLs, tokens, códigos HTTP ni JSON. Solo lee `state` y llama funciones del ViewModel.

### Pósters (`Components/MoviePosterView.swift`)

`Movie.posterURL` arma la dirección de la imagen. `MoviePosterView` la descarga con `AsyncImage` y, mientras carga o si no hay póster, muestra el ícono `film`. Lo usan `MovieCardView` (Home, búsqueda y Favoritos) y `MovieDetailView`.

Las películas de muestra (`Movie.sampleMovies`) ahora tienen la ruta real de su póster en TMDB, para que los previews se vean igual que la app.

## Llave de la API

- El token va en `MoviesApp/Utils/APIKeys.swift`, que está en `.gitignore`.
- En el repositorio solo está `APIKeys.swift.example`, con un texto de ejemplo en lugar del token.
- Cada integrante copia el ejemplo como `APIKeys.swift` y pega su token (pasos en el README).
- Se usa solo el token de lectura (`api_read`); la app no hace operaciones de escritura en TMDB.

## Parte 4: pruebas y validación

### Pruebas unitarias nuevas

Ninguna llama a TMDB: usan `MockMovieService` configurado con `moviesToReturn` o `errorToThrow`.

**`HomeStateTests`**

| Prueba | Escenario | Qué comprueba |
|---|---|---|
| `testStartsLoading` | Loading | El Home empieza en `.loading`. |
| `testSuccessfulResponseShowsContent` | 1. Éxito | Con películas, el estado es `.content` con las tres secciones. |
| `testHTTPErrorShowsError` | 2. Error HTTP | Un código 500 termina en `.error` con su mensaje. |
| `testNoConnectionShowsError` | 2. Error de conexión | Sin internet termina en `.error` con su mensaje. |
| `testEmptyResponseShowsEmpty` | 3. Sin resultados | Si no llegan películas, el estado es `.empty`. |
| `testRetryAfterErrorShowsContent` | Reintentar | Después de un error, volver a llamar `loadMovies()` con internet muestra el contenido. |
| `testLoadIfNeededKeepsContentWhenReturning` | Navegación | Al regresar al Home con películas no se vuelve a consultar. |

**`TMDBDecodingTests`**

| Prueba | Qué comprueba |
|---|---|
| `testDecodesMoviesFromTMDBResponse` | Un JSON con la forma de TMDB se decodifica y arma bien la URL del póster. |
| `testMovieWithoutPosterHasNoPosterURL` | `poster_path: null` no rompe la decodificación. |
| `testDecodesEmptyResults` | `"results": []` se decodifica como lista vacía. |
| `testDecodingFailsWithUnexpectedJSON` | El JSON de error de TMDB (sin `results`) lanza error al decodificar. |

`HomeSearchTests` ahora cargan las películas antes de buscar, porque la búsqueda filtra lo que ya se cargó. En total son 25 pruebas (9 de favoritos, 5 de búsqueda, 7 de estados y 4 de decodificación).

### Verificación contra la API

Antes de escribir el código se revisó la API directamente:

- `GET /trending/movie/week` y `GET /discover/movie?with_genres=28` responden 200 con 20 películas en `results`. Algunas traen `overview` vacío.
- Con un token inválido TMDB responde **401** con `{"status_code": 7, "status_message": "Invalid API key..."}`.
- `GET /discover/movie?with_genres=999999` responde 200 con `"results": []`, que es el caso sin resultados.

### Verificación manual en el simulador

1. Correr la app con internet: aparece "Cargando películas..." y después las tres secciones con pósters reales.
2. Error de conexión: activar modo avión en la Mac (o desconectar el Wi-Fi), cerrar y abrir la app. Debe salir el error con **Reintentar**. Reconectar y tocar Reintentar: aparecen las películas.
3. Error HTTP: cambiar una letra del token en `APIKeys.swift`. Debe salir "TMDB rechazó el token (código 401)".
4. Sin resultados: el preview "Empty" de `HomeView` (o cambiar temporalmente un id de género a `999999`).
5. Mientras carga se puede hacer scroll y tocar los botones: la pantalla no se congela.
6. Navegación: abrir el detalle, marcar favorito, abrir Favoritos, quitar con la "X", buscar y cerrar sesión. Todo debe funcionar como antes.

Los previews "Content", "Empty" y "Error" de `HomeView` muestran cada estado sin internet.

## Qué hay que hacer en Xcode

Como el `.xcodeproj` no está en el repositorio:

1. Crear `MoviesApp/Utils/APIKeys.swift` a partir del ejemplo (ver README).
2. Agregar al target de la app: `Models/TMDBMovie.swift`, `Services/MovieServiceError.swift`, `Services/Production/MovieService.swift`, `ViewModels/Home/HomeState.swift`, `Components/MoviePosterView.swift` y `Utils/APIKeys.swift`.
3. Agregar al target `MoviesAppTests`: `HomeStateTests.swift` y `TMDBDecodingTests.swift`.
4. No agregar `APIKeys.swift.example` a ningún target.
5. Compilar (⌘B) y correr las pruebas (⌘U).

## Pendientes

- La búsqueda filtra solo las películas cargadas en el Home. Falta buscar en todo TMDB con `GET /search/movie`, con sus propios estados.
- Las tres consultas del Home van una después de otra. Se podrían hacer al mismo tiempo para que cargue más rápido.
- No hay paginación: cada sección muestra la primera página (20 películas).
- Las flechas de los carruseles y el botón de listas siguen sin funcionar.
- Los favoritos guardados antes de esta práctica tienen el nombre de un ícono en `posterPath`, así que se ven con el ícono `film` en lugar del póster. Al quitarlos y volverlos a agregar ya traen el póster.
