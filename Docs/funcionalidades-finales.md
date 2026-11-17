# Funcionalidades finales

Este documento describe lo que se agregó después de la Práctica 8 para cerrar las **limitaciones conocidas** que quedaron registradas en su sección 5, y lo que se pulió para dejar la app lista.

| Limitación de la Práctica 8 | Estado |
|---|---|
| Listas personalizadas y sinopsis personal | ✅ Implementado |
| Búsqueda solo en memoria, sin `/search/movie` | ✅ Búsqueda global en TMDB |
| Sin paginación (20 resultados por sección) | ✅ "Ver más" en secciones, búsqueda y listas |
| Inicio de sesión local (cualquier usuario entraba) | ✅ Inicio de sesión real con TMDB + invitado |
| `.xcodeproj` no versionado | ✅ `movies_app.xcodeproj` con esquema compartido |

---

## 1. Listas personalizadas con nota personal

### Modelos (SwiftData)

```swift
@Model final class MovieList {
    @Attribute(.unique) var listID: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \MovieListEntry.list)
    var entries: [MovieListEntry]
}

@Model final class MovieListEntry {
    var movieID: Int
    var title, overview, posterPath: String
    var note: String        // sinopsis o nota personal del usuario
    var addedAt: Date
    var list: MovieList?
}
```

- `deleteRule: .cascade`: al borrar una lista se borran sus películas y notas.
- Igual que `FavoriteMovie`, cada entrada guarda los datos mínimos de la película para mostrarse sin internet.
- Las vistas no reciben los `@Model`, sino `CustomList` y `ListItem` (structs), igual que con `Movie` en favoritos.
- El `ModelContainer` de `movies_appApp` ahora registra `FavoriteMovie`, `MovieList` y `MovieListEntry`. SwiftData agrega las tablas nuevas sin perder los favoritos que ya existían.

### Servicio

`ListsServiceProtocol` (real: `ListsService` con SwiftData; prueba: `MockListsService`):

| Función | Uso |
|---|---|
| `fetchLists()` | Listas en orden de creación |
| `createList(named:)` | Crea una lista; rechaza nombres vacíos o repetidos (`ListsError`) |
| `deleteList(id:)` | Borra la lista con sus películas |
| `listIDs(containing:)` / `note(for:)` | Para marcar las listas y mostrar la nota en el detalle |
| `save(movie:note:inLists:)` | Deja la película **exactamente** en las listas marcadas y actualiza la nota |
| `remove(movieID:fromList:)` | Botón "X" de la pantalla de listas |

### Pantallas

- **`AddToListSheet`** (botón "Agregar a lista" del detalle): nota personal de hasta 300 caracteres, listas con casillas y un campo para crear una lista nueva. Cada cambio se guarda al momento (marcar, crear, escribir la nota) y la ventana se cierra con "Listo" o deslizando hacia abajo. Al cerrar, el botón del detalle cambia a "En 1 lista" / "En N listas" y la nota aparece en el detalle.
- **`ListsView`** (botón de lista en la barra del Home): nombre de la lista con una flecha (`Menu`) para elegir otra lista, crear una nueva o eliminarla con confirmación; películas con su nota; botón de tres puntos que muestra cinco películas más cada vez (`ListsViewModel.pageSize`).

### Navegación

`HomeView` usa un solo enum de rutas por valor:

```swift
enum AppRoute: Hashable { case favorites, lists }
```

Así se mantiene la corrección de la Práctica 8: toda la navegación del `NavigationStack` es por valor, y tocar una película en Favoritos o en Mis listas abre el detalle con el mismo `.navigationDestination(for: Movie.self)`.

---

## 2. Red: `TMDBClient`, búsqueda global y paginación

### `TMDBClient`

Los cinco pasos que antes estaban dentro de `MovieService` (armar URL, token, solicitud, validar HTTP, decodificar) pasaron a `Services/Production/TMDBClient.swift`, que comparten `MovieService` y `AuthService`. Cambios:

- **Token faltante:** si `APIKeys.swift` sigue con `PEGA_AQUI_TU_TOKEN`, lanza `MovieServiceError.missingToken` sin salir a internet, con un mensaje que dice qué archivo editar.
- **Errores de TMDB:** lee el cuerpo `{ "status_code": … }`. El código 30 es usuario o contraseña incorrectos (`invalidCredentials`) y el 32 es correo sin confirmar (`emailNotVerified`). El resto conserva `badStatus(código)`.
- **Cancelación:** si una consulta se cancela (el usuario siguió escribiendo), se avisa como `CancellationError` y nadie muestra un mensaje de error.
- Recibe la `URLSession` y el token por parámetro, así las pruebas usan respuestas simuladas.

### Endpoints

| Endpoint | Uso |
|---|---|
| `GET /trending/movie/week?page=N` | Populares de la semana |
| `GET /discover/movie?with_genres=28&page=N` | Acción |
| `GET /discover/movie?with_genres=18&page=N` | Drama |
| `GET /search/movie?query=…&page=N` | Buscador |

`TMDBMovieList` ahora decodifica `page` y `total_pages` y los convierte en `MoviePage` (`hasMore` dice si hay otra página; TMDB no permite pasar de la 500).

### Home

- Las tres secciones se piden al mismo tiempo con `async let`.
- `MovieSection` guarda `kind` (`.popular` o `.genre(id)`), `page` y `totalPages`. La tarjeta "Ver más" llama a `loadMore(in:)`, que agrega la página siguiente quitando películas repetidas. Si falla, se muestra una alerta y no se borra lo que ya se veía.

### Buscador

- `SearchState` (`idle`, `loading`, `results(_, canLoadMore:)`, `empty`, `error`) funciona como `HomeState`.
- La vista usa `.task(id: searchText)` con una espera de 450 ms: si el usuario escribe otra letra, SwiftUI cancela la consulta anterior. Además, una respuesta que llega para un texto viejo se descarta.

---

## 3. Inicio de sesión con TMDB

Flujo oficial de la API v3 (`AuthService`):

1. `GET /authentication/token/new` → token temporal.
2. `POST /authentication/token/validate_with_login` con `username`, `password` y `request_token`.
3. `POST /authentication/session/new` → `session_id`.

- **Invitado:** `GET /authentication/guest_session/new`.
- **Cerrar sesión:** `DELETE /authentication/session` (las de invitado vencen solas).
- **Sesión guardada:** `UserSession` se guarda en el **Llavero** (`KeychainSessionStorage`, accesible solo con el teléfono desbloqueado y sin pasar a otros dispositivos). `AuthStore` la recupera al abrir la app. La contraseña nunca se guarda.
- `AuthStore` recibe `AuthServiceProtocol` y `SessionStorageProtocol`, así las pruebas usan `MockAuthService` e `InMemorySessionStorage`.
- El campo dice "Usuario de TMDB" porque la API valida con el nombre de usuario, no con el correo.

---

## 4. Detalles de interfaz

- Textos traducidos al español ("Populares de la semana", "Buscar", "Sinopsis", "Agregar a favoritos", "FAVORITOS"…).
- El detalle tiene `ScrollView` (antes una sinopsis larga se cortaba) y botones fijos abajo.
- Tipografías con estilos del sistema (`.title3`, `.body`, `.headline`…) que respetan el tamaño de letra del iPhone.
- Etiquetas de VoiceOver en los botones que solo tienen ícono.
- Ícono de la app en `Assets.xcassets/AppIcon.appiconset`.
- La app se fija en **modo claro** (`UIUserInterfaceStyle = Light`): su diseño es blanco y negro de alto contraste, y en modo oscuro el texto escrito quedaba blanco sobre los campos blancos.
- Las tarjetas de películas crecen con el tamaño de letra (`@ScaledMetric`), para que el título y la sinopsis no se corten.
- Se reactivó el gesto de **deslizar desde el borde para regresar** (`Utils/SwipeBackGesture.swift`), que iOS apaga al esconder la flecha del sistema.
- Al regresar del detalle, la búsqueda conserva los resultados y páginas que ya se habían cargado.
- La sesión se guarda en el Llavero con `AfterFirstUnlockThisDeviceOnly`, para que se lea aunque iOS prepare la app con el teléfono bloqueado.

---

## 5. Proyecto de Xcode

- `movies_app.xcodeproj` con los targets `movies_app` y `MoviesAppTests` y el esquema compartido `movies_app` (`xcshareddata`), así `⌘R` y `⌘U` funcionan en cualquier Mac recién clonada.
- La fase **"Crear APIKeys.swift si falta"** copia la plantilla si no existe el archivo del token, para que el proyecto compile. La app muestra el mensaje de token faltante hasta que se pegue uno.

---

## 6. Pruebas

**62 pruebas** con XCTest, ninguna usa internet:

| Clase | Pruebas | Qué cubre |
|---|---|---|
| `FavoritesTests` | 9 | Igual que en la Práctica 6 |
| `ListsTests` | 14 | Crear listas (también desde la ventana del detalle, guardando la película al momento), nota, mover entre listas, borrar en cascada, nombres inválidos, persistencia, "…" de cinco en cinco, selector de lista, ventana "Agregar a lista", límite de 300 caracteres |
| `AuthTests` | 7 | Login correcto y sesión guardada, invitado, sesión recuperada al abrir, cerrar sesión, campos vacíos, contraseña incorrecta, token faltante |
| `HomeSearchTests` | 10 | Búsqueda en TMDB sin cargar el Home, espacios, solo espacios, "Cargar más resultados", sin resultados, error, borrar texto, conservar resultados al regresar del detalle, "Reintentar" forzado, página vieja que llega tarde |
| `HomeStateTests` | 9 | Estados del Home + "Ver más" sin duplicados y error al cargar más |
| `TMDBDecodingTests` | 6 | JSON de TMDB + página y tope de 500 páginas |
| `TMDBNetworkTests` | 7 | Con `URLProtocol` simulado: URL y token de la búsqueda, token faltante, 401 de token, flujo completo de login, contraseña incorrecta (status 30), token de solicitud vencido (status 33) e invitado |
