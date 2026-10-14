
# Práctica 4

## Flujo del MVP

- Flujo de Acceso: Alternar entre LoginView y el home sin apilar login en el stack de retroceso
- Flujo de Pantallas: NavigationStack para navegar entre Home ⇄ MovieDetail, Home ⇄ FavoritesView, y FavoritesView ⇄ MovieDetail.
- Cierre de Sesión: Botón de cuenta para regresar a LoginView

## Caso de uso real con los Favoritos
- Se va a crear la clase FavoritesStore, que es una clase @Observable que gestiona el arreglo local de películas favoritas ([Movie])
- MovieDetail lee si la película ya es favorita y permite agregarla/quitarla
- FavoritesView lee la misma lista compartida en tiempo real y permite quitar películas con la "X"
- Ambas vistas reflejan los cambios porque comparten la misma instancia

