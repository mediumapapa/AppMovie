## Proyecto Integrador

Elección de proyecto:

**Opción A** · Aplicación de películas con TMDB 

**Objetivo**: Permitir explorar películas, buscar una película, consultar su información y administrar favoritas.

Equipo:

- Guerrero Colín Santiago
- Ávila Aguilar Alberto

## Flujos 

<img width="1920" height="1080" alt="Historia de Instagram Pantalla Teléfono Celular Fin de Semana Llamando Foto Relax Minimalista Negro" src="https://github.com/user-attachments/assets/d6cf4389-c5a0-4685-96d4-ca391fef55f8" />

1) Pantalla de inicio -> lista de películas -> detalle de la película

2) Pantalla de inicio -> búsqueda -> resultado -> detalle de la película

3) Pantalla de inicio -> favoritos -> película guardadas -> detalle de la película

4) Pantalla de inicio -> listas personalizadas -> películas listadas -> detalle de la película


## Especificación de pantallas

#### **Home**

<img width="1080" height="1920" alt="1" src="https://github.com/user-attachments/assets/f943af33-af07-4580-9b54-4cb9f9933d61" />

La pantalla principal de la aplicación. 
- En la parte superior derecha estarán los botones para acceder a las listas personalizadas, favoritos y la cuenta del usuario
- Se incorporará un buscador de películas, el resultado nos llevará a la pantalla de detalle de cada película
- Se mostrará por secciones (popularidad y géneros) las películas disponibles. En cada sección habrá flechas de navegación para recorrer toda la lista
- Al presionar cualquier película, nos llevará a la pantalla de detalle


### Movie Detail

<img width="1080" height="1920" alt="3" src="https://github.com/user-attachments/assets/e23e05a6-32fa-4f46-af7b-ee0ed5fc1b66" />

Pantalla de detalle de cada película
- Nos mostrará información básica de cada película: Titulo, portada de lanzamiento y una descripción general
- En la parte inferior de la pantalla, se dispondrá de un botón para añadir a favoritos, y enseguida un botón para añadir a listas personalizadas
- Al momento de presionar el botón de las listas personalizadas, nos mostrará una ventana para seleccionar a qué lista guardar la película o si se desea crear una nueva lista (pedirá el nombre).
- En la parte superior izquierda, se dispondrá de un botón de retroceso

### Favorites

<img width="1080" height="1920" alt="2" src="https://github.com/user-attachments/assets/2ca49dae-680e-45b9-b6d0-79296f233626" />

La pantalla de favoritos.
- Aquí se almacenarán las películas que deseemos añadir a favoritos
- Al presionar cualquier película, nos llevará a la pantalla de detalle
- Podremos eliminar películas de favoritos, presionando la "X" ubicada en la esquina superior derecha de cada elemento
- Del lado superior izquierdo de la pantalla, habrá una flecha de retroceso 

### List

<img width="1080" height="1920" alt="4" src="https://github.com/user-attachments/assets/1156b120-4e81-4275-b541-60196193530c" />

Listas personalizadas-
- Aquí se mostrará las listas personalizadas con las películas en cada una
- Inmediatamente al costado derecho de la lista, habrá una flecha que nos permitirá seleccionar entre las listas que tengamos creadas
- En la parte inferior de la pantalla, se dispondrá un botón (tres círculos) para cargar el resto de películas si es que es necesario
- En la parte superior izquierda habrá un botón de retroceso
