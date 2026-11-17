# Práctica 8: Documentación Técnica y Preparación de Entrega

Este documento consolida la documentación técnica de **TMDB Movies (`MoviesApp`)** correspondiente a su versión de entrega: arquitectura implementada, consumo de red (Networking), persistencia local, decisiones técnicas, limitaciones conocidas y resultados de la revisión del repositorio.

---

## 1. Arquitectura

La aplicación está organizada bajo el patrón **MVVM (Model - View - ViewModel)** apoyado en una capa de **Servicios basados en protocolos** y el macro `@Observable` del framework `Observation` de Swift.

### Diagrama general de capas

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              Views (SwiftUI)                             │
│         LoginView · HomeView · MovieDetailView · FavoritesView           │
│   Components: AppHeaderBar, MovieCardView, MoviePosterView, SectionView  │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ eventos de usuario / lectura de estado (@Observable)
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                                ViewModels                                │
│  LoginViewModel · HomeViewModel (+ HomeState) · MovieDetailViewModel ·   │
│                             FavoritesViewModel                           │
└───────────────┬────────────────────┴───────────────────┬─────────────────┘
                │                                        │
                ▼                                        ▼
┌───────────────────────────────┐        ┌─────────────────────────────────┐
│     MovieServiceProtocol      │        │    FavoritesServiceProtocol     │
├───────────────────────────────┤        ├─────────────────────────────────┤
│ Production: MovieService      │        │ Production: FavoritesService    │
│   (URLSession + TMDB API v3)  │        │   (SwiftData ModelContext)      │
│ Mock: MockMovieService        │        │ Mock: MockFavoritesService      │
│   (Datos en memoria)          │        │   (Arreglo en memoria)          │
└───────────────┬───────────────┘        └───────────────┬─────────────────┘
                │                                        │
                ▼                                        ▼
┌───────────────────────────────┐        ┌─────────────────────────────────┐
│ Models: TMDBMovie → Movie     │        │ Models: FavoriteMovie ↔ Movie   │
└───────────────────────────────┘        └─────────────────────────────────┘
```

### Responsabilidades de los componentes principales

| Carpeta / Componente | Responsabilidad |
|---|---|
| **`movies_appApp.swift`** | Punto de entrada (`@main`). Inicializa y conserva el `ModelContainer` de SwiftData, el estado de sesión (`AuthStore`) y las instancias de producción (`MovieService` y `FavoritesService`), alternando entre `LoginView` y `HomeView` según `authStore.isLoggedIn`. |
| **`Models/`** | Estructuras de datos puras sin lógica de interfaz:<br>• `Movie`: modelo de dominio principal (`id: Int`, `title`, `overview`, `posterPath` y `posterURL`).<br>• `MovieSection`: agrupa un título de sección y su arreglo `[Movie]` para los carruseles del Home.<br>• `FavoriteMovie`: entidad `@Model` persistida con SwiftData.<br>• `TMDBMovieList` y `TMDBMovie`: modelos `Decodable` que representan el JSON devuelto por TMDB y lo transforman a `Movie`. |
| **`State/AuthStore.swift`** | Clase `@Observable` compartida que mantiene el estado de autenticación (`isLoggedIn` y `currentUser`) y valida que las credenciales ingresadas no estén vacías. |
| **`Services/`** | Define los contratos `MovieServiceProtocol` y `FavoritesServiceProtocol`, además de `MovieServiceError`. Sus implementaciones están divididas en:<br>• `Production/`: `MovieService` (red real con TMDB) y `FavoritesService` (persistencia real con SwiftData).<br>• `Mock/`: `MockMovieService` y `MockFavoritesService` para `#Preview` y pruebas unitarias aisladas. |
| **`ViewModels/`** | Intermediarios `@Observable` entre cada vista y los servicios:<br>• `LoginViewModel`: administra los campos del formulario, visibilidad de contraseña y mensajes de error.<br>• `HomeViewModel` (`@MainActor`): administra `state: HomeState`, solicita las secciones a `MovieServiceProtocol`, filtra localmente las películas en `searchResults`, consulta si hay favoritos para el indicador rojo y construye los ViewModels de navegación (`makeMovieDetailViewModel` y `makeFavoritesViewModel`).<br>• `MovieDetailViewModel`: consulta si la película está en favoritos, expone el texto/ícono del botón y ejecuta `toggleFavorite()`.<br>• `FavoritesViewModel`: carga la lista de favoritos (`loadFavorites()`) y elimina elementos (`remove(_:)`). |
| **`Views/` y `Components/`** | Dibujan la interfaz declarativa sin conocer detalles de HTTP, JSON ni SwiftData. Reutilizan componentes visuales como `AppHeaderBar`, `BorderedFieldModifier`, `MovieCardView`, `MoviePosterView` y `MovieSectionView`. |
| **`Utils/`** | Constantes de color (`AppColors`), enlaces web hacia TMDB (`AppLinks`) y el token de lectura (`APIKeys.swift`, generado localmente a partir de `APIKeys.swift.example`). |

---

## 2. Networking

El consumo de datos remotos está encapsulado en `MoviesApp/Services/Production/MovieService.swift` y utiliza **`URLSession`**, concurrencia estructurada de Swift (**`async/await`**) y **`JSONDecoder`**.

### API y autenticación

- **Servicio:** API REST de The Movie Database (TMDB) v3.
- **URL base:** `https://api.themoviedb.org/3`
- **Idioma configurado:** parámetro de consulta `language=es-MX` en todas las peticiones para recibir títulos y sinopsis en español de México.
- **Autenticación:** Token de acceso de lectura a la API (*Bearer Token*) enviado en el encabezado HTTP:
  - `Authorization: Bearer <APIKeys.tmdbReadAccessToken>`
  - `Accept: application/json`

### Endpoints principales

| Endpoint | Método | Uso en la aplicación |
|---|---|---|
| `/trending/movie/week` | `GET` | Obtiene las películas en tendencia de la semana para la sección **"Popular this week"** (`popularMovies()`). |
| `/discover/movie?with_genres=28` | `GET` | Obtiene las películas del género Acción (`genreID = 28`) para la sección **"Action"** (`movies(forGenreID: 28)`). |
| `/discover/movie?with_genres=18` | `GET` | Obtiene las películas del género Drama (`genreID = 18`) para la sección **"Drama"** (`movies(forGenreID: 18)`). |
| `https://image.tmdb.org/t/p/w500/<poster_path>` | `GET` | Descarga asíncrona de pósters de 500 px de ancho mediante `AsyncImage` dentro de `MoviePosterView`. |

### Modelos de respuesta y manejo de errores

- **`TMDBMovieList` y `TMDBMovie` (`Models/TMDBMovie.swift`):**
  - `TMDBMovieList` decodifica únicamente el arreglo `results: [TMDBMovie]`, ignorando metadatos de paginación (`page`, `total_pages`, `total_results`).
  - `TMDBMovie` decodifica `id: Int`, `title: String`, `overview: String` y `posterPath: String?` (mapeado desde `"poster_path"` mediante `CodingKeys`). Como TMDB envía `poster_path: null` cuando una película carece de póster, la propiedad es opcional y al convertirse a `Movie` (`var movie: Movie`) usa `posterPath ?? ""`.
- **`MovieServiceError` (`Services/MovieServiceError.swift`):**
  - Implementa `LocalizedError` para traducir cualquier fallo técnico en un mensaje legible por el usuario en `HomeView`:
    - `.invalidURL`: fallo al construir `URLComponents`.
    - `.noConnection`: error de red o falta de conexión a internet al ejecutar `URLSession.shared.data(for:)`.
    - `.invalidResponse`: la respuesta no es un `HTTPURLResponse`.
    - `.badStatus(401)`: token faltante o inválido (*"TMDB rechazó el token (código 401). Revisa el archivo APIKeys.swift."*).
    - `.badStatus(Int)`: cualquier otro código fuera del rango `200...299`.
    - `.decodingFailed`: el JSON recibido no coincide con la estructura esperada por `TMDBMovieList`.

---

## 3. Persistencia

### Información almacenada localmente

Se almacena localmente **únicamente la lista de películas favoritas del usuario**. El catálogo general del Home se solicita siempre a TMDB al iniciar la app, mientras que los favoritos deben permanecer disponibles en el teléfono al cerrar y volver a abrir la aplicación (incluso sin conexión).

### Mecanismo utilizado: SwiftData

- **Modelo persistente (`Models/FavoriteMovie.swift`):**
  ```swift
  @Model
  final class FavoriteMovie {
      @Attribute(.unique) var movieID: Int
      var title: String
      var overview: String
      var posterPath: String
      var addedAt: Date
  }
  ```
  - `movieID` guarda el identificador oficial de TMDB con la restricción `@Attribute(.unique)` para impedir registros duplicados en la base de datos.
  - `title`, `overview` y `posterPath` almacenan los datos mínimos necesarios para renderizar las tarjetas en `FavoritesView` y el detalle sin hacer consultas adicionales a la red.
  - `addedAt` registra la fecha de inserción para ordenar los favoritos cronológicamente (`SortDescriptor(\.addedAt)`).
- **Servicio de persistencia (`Services/Production/FavoritesService.swift`):**
  - Recibe el `ModelContext` principal (`container.mainContext`) creado por `movies_appApp`.
  - Consulta registros con `FetchDescriptor<FavoriteMovie>`, verifica existencia y filtra por `movieID` mediante `#Predicate { $0.movieID == movieID }`, e invoca `context.insert(...)`, `context.delete(...)` y `try? context.save()`.

---

## 4. Decisiones técnicas

1. **Filosofía de diseño minimalista para un público "old school":**
   La aplicación está dirigida a veteranos que disfrutan y tienen el hábito de ver películas (generalmente personas mayores). A diferencia de otros usuarios, no necesitan motores de recomendaciones algorítmicas, carruseles publicitarios ni funciones sociales complejas. Por ello, se optó por una interfaz **minimalista**, de alto contraste (fondo blanco, bordes definidos, tipografía clara y barra superior identificable), mostrando únicamente lo esencial: póster, título, sinopsis y acceso directo a sus películas favoritas.
2. **Inyección de dependencias por protocolo (`Production` vs. `Mock`):**
   Los ViewModels dependen de `MovieServiceProtocol` y `FavoritesServiceProtocol` en lugar de clases concretas. Esto permitió crear `MockMovieService` y `MockFavoritesService`, logrando que los `#Preview` de SwiftUI (incluyendo los estados *Content*, *Empty* y *Error* del Home) y las 25 pruebas unitarias de `XCTest` se ejecuten en memoria, de forma determinista y sin conexión a internet.
3. **Eliminación de `FavoritesStore` intermedio:**
   Tras la revisión de la Práctica 6, se eliminó la clase intermedia `FavoritesStore` para que `HomeViewModel`, `MovieDetailViewModel` y `FavoritesViewModel` se comuniquen directamente con `FavoritesServiceProtocol` compartiendo el mismo `ModelContext`. Así la base de SwiftData es la única fuente de verdad y las vistas se sincronizan en `.onAppear`.
4. **Modelado de estados excluyentes con `HomeState` y `@MainActor`:**
   En lugar de manejar banderas booleanas sueltas (`isLoading`, `hasError`, `sections`), `HomeViewModel` define un único enum `HomeState: Equatable` (`.loading`, `.content([MovieSection])`, `.empty`, `.error(String)`). Esto hace imposible que la interfaz muestre películas y una pantalla de error simultáneamente. Además, `loadMoviesIfNeeded()` evita recargar la API cada vez que el usuario regresa desde el detalle.
5. **Identificador estable de TMDB (`Movie.id: Int`):**
   Se reemplazó el `UUID()` autogenerado de las primeras prácticas por el `id: Int` oficial de TMDB. De esta forma, una película guardada en SwiftData se reconoce como la misma película cuando vuelve a descargarse de la API.
6. **Seguridad del token de TMDB (`APIKeys.swift` fuera de Git):**
   Para evitar exponer credenciales en el historial del repositorio, `MoviesApp/Utils/APIKeys.swift` se incluyó en `.gitignore` y se documentó el flujo de configuración local a partir de `APIKeys.swift.example`.
7. **Eliminación de las flechas de navegación en las secciones del Home (`MovieSectionView.swift`):**
   En el wireframe inicial cada sección del Home contemplaba dos flechas laterales (`arrowtriangle.backward.fill` y `arrowtriangle.forward.fill`) junto al título. En esta práctica **se eliminaron las flechas de navegación de `MovieSectionView` para conservar únicamente el `ScrollView` horizontal** ya implementado, reforzando el diseño minimalista de la aplicación y evitando elementos visuales que no tenían acción asociada.
8. **Corrección del flujo de navegación de Favoritos a Detalle (`HomeView.swift`):**
   - *Problema detectado:* Al marcar una película como favorita, entrar a `FavoritesView` y tocar la tarjeta para ver su detalle (`MovieDetailView`), la transición no ocurría y la pantalla permanecía en Favoritos; sin embargo, al presionar el botón de retroceso aparecían acumuladas las pantallas de detalle de las películas presionadas anteriormente.
   - *Causa y solución aplicada:* `HomeView` abría `FavoritesView` mediante `NavigationLink(destination:)`, mientras que las tarjetas de películas en `HomeView` y `FavoritesView` usaban `NavigationLink(value: movie)` con `.navigationDestination(for: Movie.self)`. Mezclar navegación por vista (`destination:`) y navegación por valor (`value:`) dentro del mismo `NavigationStack` desincronizaba la pila de SwiftUI. Se corrigió en `HomeView.swift` definiendo `FavoritesRoute` (`Hashable`) y usando `NavigationLink(value: FavoritesRoute.favorites)` junto con `.navigationDestination(for: FavoritesRoute.self)`, unificando toda la navegación por valor.

---

## 5. Limitaciones conocidas y funcionalidades pendientes

> **Actualización:** las limitaciones de esta sección ya se resolvieron (listas personalizadas con nota personal, búsqueda global con `/search/movie`, paginación e inicio de sesión real con TMDB). Ver [funcionalidades-finales.md](funcionalidades-finales.md). Se conserva el texto original como registro de la entrega de la Práctica 8.

### Funcionalidades incompletas

1. **Listas personalizadas (`List`) y sinopsis personal del usuario:**
   - Tal como se muestra en la especificación de pantallas del `README.md`, queda pendiente para una siguiente etapa implementar la funcionalidad de **listas personalizadas** (actualmente el botón `+` en la barra superior de `HomeView` y el botón `+ Add List` en `MovieDetailView` no tienen acción asociada).
   - El alcance planeado para esta funcionalidad contempla:
     - Al presionar `+ Add List` en el detalle de una película, mostrar una ventana para seleccionar en qué lista guardarla o crear una nueva lista ingresando su nombre, además de permitir que el usuario escriba una **pequeña sinopsis o nota personal** para cada película.
     - Una pantalla de **Listas personalizadas** donde se muestren las películas guardadas en cada lista junto con la sinopsis personal del usuario.
     - Inmediatamente al costado derecho del nombre de la lista, una flecha que permita seleccionar entre las listas creadas.
     - En la parte inferior de la pantalla, un botón de tres círculos (`...`) para cargar el resto de películas si es necesario.
2. **Búsqueda global y autenticación remota en TMDB:**
   - El buscador del Home filtra en memoria las películas ya descargadas en las secciones activas; no consulta el endpoint remoto `GET /search/movie` ni implementa paginación más allá de la primera página (20 resultados por sección).
   - El inicio de sesión en `AuthStore` es local para el flujo del MVP, mientras que el registro y la recuperación de contraseña redirigen al navegador con `AppLinks`.

---

## 6. Revisión del repositorio y pruebas ejecutadas

Durante la revisión general para la entrega (Partes 3 y 4) se verificó lo siguiente:

- **Limpieza de archivos temporales:** Se eliminó del índice de Git el archivo temporal `.DS_Store` de macOS que había quedado rastreado en la raíz del repositorio desde la inicialización del proyecto (`.gitignore` ya previene que se agreguen nuevos archivos `.DS_Store`, `._*`, `DerivedData/` o `xcuserdata/`).
- **Seguridad de credenciales:** Se verificó que no existan tokens ni claves reales de TMDB en ningún archivo rastreado por Git. En el repositorio únicamente se incluye `MoviesApp/Utils/APIKeys.swift.example`.
- **Pruebas unitarias (`MoviesAppTests/`):** El proyecto cuenta con **25 pruebas unitarias** automatizadas con `XCTest`:
  - `FavoritesTests` (**9 pruebas**): inserción en SwiftData, eliminación individual con el botón `"X"`, indicador de favoritos en el Home, prevención de duplicados por `movieID`, alternancia (`toggleFavorite`) en el detalle, estado inicial vacío, eliminación de película no guardada y persistencia entre distintas instancias del servicio sobre el mismo contenedor.
  - `HomeSearchTests` (**5 pruebas**): búsqueda por título sin importar mayúsculas/minúsculas ni duplicados entre secciones, búsqueda en la sinopsis (`overview`), recorte de espacios alrededor del texto, texto de solo espacios y búsqueda sin coincidencias.
  - `HomeStateTests` (**7 pruebas**): estado inicial `.loading`, transición a `.content` con las tres secciones, error HTTP (`500`), error sin conexión a internet, estado `.empty`, recuperación mediante `loadMovies()` al presionar **Reintentar**, y conservación del contenido al regresar al Home con `loadMoviesIfNeeded()`.
  - `TMDBDecodingTests` (**4 pruebas**): decodificación de respuesta válida de TMDB y construcción de `posterURL`, manejo de `poster_path: null`, arreglo `"results": []` vacío y fallo controlado ante un JSON de error inesperado.
