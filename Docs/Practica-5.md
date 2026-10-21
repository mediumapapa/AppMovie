# Práctica 5: Reorganización hacia MVVM

En esta práctica reorganizamos el proyecto para empezar a trabajar con MVVM. La idea fue ordenar lo que ya teníamos sin cambiar cómo se ve ni cómo funciona la app. Tomamos como guía la estructura del proyecto Orumi que se vio en clase.

## Problemas que encontramos

- Todos los archivos estaban sueltos en la raíz del repositorio, mezclados con la documentación.
- Había archivos `._ContentView.swift`, `._movies_appApp.swift` y `._Assets.xcassets`. Son copias que genera macOS al pasar archivos por USB y no sirven para nada.
- `ContentView` y `LoginView` tenían los datos de la pantalla y la lógica dentro de la vista (búsqueda, filtro, validación del login).
- La barra cyan de arriba estaba copiada tres veces (Login, Home y Favoritos).
- `FavoritesView` armaba su propia tarjeta de película, casi igual a `MovieCardView`.
- El estilo de los campos con borde negro estaba repetido en el buscador y en el login.
- `MovieSectionView` tenía una variable `onSelectMovie` que nunca se usaba.
- Las películas de prueba estaban dentro del modelo `Movie`, y las vistas las leían directo con `Movie.sampleMovies`.
- Las URLs de TMDB del login se creaban con `!` dentro de la vista.

## Nueva estructura

```
MoviesApp/
├── movies_appApp.swift
├── Models/          Movie, MovieSection
├── State/           AuthStore, FavoritesStore
├── Services/        MovieServiceProtocol
│   └── Mock/        MockMovieService (películas de prueba)
├── ViewModels/
│   ├── Home/        HomeViewModel
│   ├── Login/       LoginViewModel
│   ├── MovieDetail/ MovieDetailViewModel
│   └── Favorites/   FavoritesViewModel
├── Views/
│   ├── Home/        HomeView
│   ├── Login/       LoginView
│   ├── MovieDetail/ MovieDetailView
│   └── Favorites/   FavoritesView
├── Components/      AppHeaderBar, BorderedFieldModifier, MovieCardView, MovieSectionView
├── Utils/           AppColors, AppLinks
└── Resources/       Assets.xcassets
Docs/                Prácticas y diseño de navegación
```

## Qué hace cada capa

- Models: solo datos. `Movie` ya no tiene la lista de prueba adentro.
- State: `AuthStore` y `FavoritesStore` se quedan igual. Son el estado que comparte toda la app (la sesión y la lista de favoritos).
- Services: `MovieServiceProtocol` dice qué películas se pueden pedir. Por ahora lo cumple `MockMovieService` con los datos locales. Cuando conectemos la API de TMDB solo hay que agregar otro servicio que cumpla el mismo protocolo, y los ViewModels no cambian.
- ViewModels: cada pantalla tiene el suyo, marcado con `@Observable`. Guardan lo que el usuario escribe y deciden qué mostrar.
- Views: solo dibujan la pantalla y le avisan al ViewModel cuando el usuario toca algo.
- Components: piezas visuales que se usan en varias pantallas.

## Cambios por pantalla

### Login
`LoginViewModel` guarda `username`, `password`, `isPasswordVisible` y `errorMessage`. La función `login()` llama a `AuthStore` y pone el mensaje de error si los campos están vacíos. Antes eso estaba en `handleLogin()` dentro de la vista.

### Home
`ContentView` ahora se llama `HomeView`. `HomeViewModel` tiene el texto del buscador, los resultados de la búsqueda (se los pide al servicio), las secciones del Home y la alerta de cerrar sesión. Las tres secciones ya no están escritas a mano en la vista: se recorren con un `ForEach` sobre `viewModel.sections`.

El Home también crea los ViewModels de las pantallas a las que navega (`makeMovieDetailViewModel` y `makeFavoritesViewModel`), igual que en Orumi.

### Detalle de película
`MovieDetail` ahora se llama `MovieDetailView` y se quitó el `typealias` que tenía. `MovieDetailViewModel` dice si la película es favorita, qué ícono y texto mostrar en el botón, y hace el cambio en `FavoritesStore`.

### Favoritos
`FavoritesViewModel` da la lista de favoritos y quita películas. La tarjeta repetida se borró y ahora se usa `MovieCardView` con el estilo `.compact`, que tiene las mismas medidas que la tarjeta anterior.

## Cómo se pasan los datos

Antes las vistas leían los stores con `@Environment`. Ahora `movies_appApp` crea `AuthStore`, `FavoritesStore` y el servicio, y se los pasa a cada ViewModel por su `init`. Cada vista recibe su ViewModel también por `init` y lo guarda en `@State`. Como los stores son la misma instancia en toda la app, al marcar una película como favorita en el detalle se ve el cambio en Favoritos y en el puntito rojo del corazón del Home.

## Qué no cambió

- El diseño de las pantallas, los textos y los colores.
- El flujo: Login → Home → Detalle, Home → Favoritos → Detalle, y cerrar sesión desde el menú de la cuenta.
- `AuthStore` y `FavoritesStore`.
- El nombre del struct `movies_appApp`, para no mover la configuración del target en Xcode.

## Pendiente

- Conectar la API de TMDB con un servicio real.
- Las listas personalizadas (los botones "+" y "Add List" todavía no hacen nada).
- Al bajar el proyecto hay que revisar en Xcode que todos los archivos estén en el target, porque cambiaron de carpeta. Si alguno sale en rojo, se arrastra la carpeta `MoviesApp` al proyecto con la opción "Create groups".
