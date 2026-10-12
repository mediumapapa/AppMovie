# Práctica 4: Navegación y Organización del Estado en Código

## 1. Objetivo de la Práctica
Llevar a código las decisiones de navegación y organización del estado definidas en la Práctica 3, atendiendo la retroalimentación docente:
1. Implementar el flujo principal de navegación del MVP.
2. Implementar un caso real de información compartida entre vistas (Favoritos como flujo local).

---

## 2. Atención a la Retroalimentación Docente

| Observación del Docente | Ajuste Implementado en Código |
| :--- | :--- |
| **Flujo de Favoritos Local**: En la Práctica 3 se propuso guardar favoritos en TMDB mediante llamadas API. El docente señaló que la función de favoritos se planteó como un flujo local y que depender de TMDB crearía una latencia o dependencia innecesaria. | Se creó la clase `@Observable` `FavoritesStore` como gestor de estado en memoria local compartido para toda la aplicación mediante `@Environment`. Permite agregar, consultar y eliminar películas favoritas en tiempo real. |
| **Película Seleccionada en Home**: El docente señaló: *"Si se va a enviar entonces no es necesario que viva en Home"*. | Se eliminó la variable `@State private var selectedMovie: Movie?` y el modificador modal `.fullScreenCover` de `ContentView`. En su lugar, se implementó navegación tipada con `NavigationLink(value: movie)` dentro de un `NavigationStack`. |

---

## 3. Resumen de Archivos y Cambios

### Archivos Nuevos
1. **`state/FavoritesStore.swift`**:
   - Clase observable que administra el arreglo compartido de favoritos (`[Movie]`).
   - Métodos: `isFavorite(_:)`, `add(_:)`, `remove(_:)` y `toggle(_:)`.
2. **`state/AuthStore.swift`**:
   - Clase observable que administra la sesión del usuario (`isLoggedIn`, `currentUser`).
   - Métodos: `login(username:password:)` y `logout()`.
3. **`views/login/LoginView.swift`**:
   - Pantalla de inicio de sesión implementada según especificación de `README.md`.
   - Incluye barra superior sin botones de acción, campos de usuario y contraseña con alternador de visibilidad (ojo), botón "Ingresar" con validación y enlaces web externos a TMDB.
4. **`views/favorites/FavoritesView.swift`**:
   - Pantalla de favoritos en cuadrícula de dos columnas.
   - Botón "X" en cada tarjeta para eliminar de favoritos directamente en el store.
   - Tocar una tarjeta navega a `MovieDetail` pasando la película seleccionada.
   - Botón de retroceso personalizado en la barra superior.

### Archivos Modificados
1. **`Movie.swift`**:
   - Se añadió la conformidad al protocolo `Hashable` (`Identifiable, Hashable`) para soportar la navegación de SwiftUI con `NavigationLink(value:)`.
2. **`movies_appApp.swift`**:
   - Instanciación de los stores compartidos (`AuthStore`, `FavoritesStore`).
   - Orquestación de la navegación raíz: si `isLoggedIn` es `false`, se muestra `LoginView`; si es `true`, se muestra `NavigationStack { ContentView() }`.
3. **`views/home/ContentView.swift`**:
   - Eliminación del estado `selectedMovie`.
   - Integración de `NavigationLink(destination: FavoritesView())` en el botón de corazón del encabezado con indicador visual.
   - Integración de cierre de sesión en el botón de perfil.
   - Buscador en vivo que filtra el catálogo y muestra resultados navegables hacia el detalle.
   - Destino de navegación registrado con `.navigationDestination(for: Movie.self)`.
4. **`views/home/MovieSectionView.swift`**:
   - Reemplazo del callback manual `onSelectMovie` por `NavigationLink(value: movie)`.
5. **`views/home/detail/MovieDetail.swift`**:
   - Conexión del botón "Add Favorite" con `FavoritesStore.toggle(movie)`.
   - Cambio dinámico de icono y etiqueta (`heart.fill` en rojo si ya es favorita).
   - Ocultamiento de la barra de retroceso nativa para usar el botón de retroceso integrado de la interfaz.

---

## 4. Flujos de Navegación Verificados

```
[LoginView] ──(Ingresar con éxito)──► [ContentView (Home)]
                                             │
      ┌──────────────────────────────────────┼──────────────────────────────────────┐
      ▼                                      ▼                                      ▼
[MovieDetail] ◄──────(Ver detalle)──── [FavoritesView]                        [Búsqueda en Home]
(Agregar/Quitar Fav)                   (Eliminar con 'X')                              │
                                                                                       ▼
                                                                                 [MovieDetail]
```
