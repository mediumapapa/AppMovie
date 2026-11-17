import SwiftUI

// Pantalla "Mis listas" (pantalla List del wireframe).
// - Arriba, el nombre de la lista con una flecha a su derecha para elegir entre las listas creadas.
// - En medio, las películas de la lista con la nota personal del usuario.
// - Abajo, un botón de tres puntos para mostrar el resto de películas.
struct ListsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ListsViewModel

    init(viewModel: ListsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if viewModel.hasLists {
                listContent
            } else {
                emptyStateView
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        // Al aparecer y al regresar del detalle, por si ahí se cambiaron las listas de una película
        .onAppear {
            viewModel.loadLists()
        }
        .alert("Nueva lista", isPresented: $viewModel.showCreateListAlert) {
            TextField("Nombre de la lista", text: $viewModel.newListName)
            Button("Cancelar", role: .cancel) { }
            Button("Crear") {
                viewModel.createList()
            }
        } message: {
            Text("Por ejemplo: Clásicos de domingo")
        }
        .alert("¿Eliminar la lista?", isPresented: $viewModel.showDeleteListAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                withAnimation {
                    viewModel.deleteSelectedList()
                }
            }
        } message: {
            Text("Se borrará \"\(viewModel.selectedList?.name ?? "")\" con sus películas y notas. Esto no se puede deshacer.")
        }
        .alert(
            "No se pudo crear la lista",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Barra superior

    private var headerBar: some View {
        AppHeaderBar {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            .accessibilityLabel("Regresar")

            Spacer()

            AppHeaderTitle(text: "MIS LISTAS", size: 24)

            Spacer()

            Button(action: viewModel.startCreatingList) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            .accessibilityLabel("Crear lista nueva")
        }
    }

    // MARK: - Lista seleccionada

    private var listContent: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                listSelector

                if let list = viewModel.selectedList {
                    Text(list.items.count == 1 ? "1 película" : "\(list.items.count) películas")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))

                    if list.items.isEmpty {
                        emptyListMessage
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.visibleItems) { item in
                                row(for: item)
                            }
                        }

                        if viewModel.canLoadMore {
                            loadMoreButton
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    // Nombre de la lista con la flecha para elegir otra
    private var listSelector: some View {
        Menu {
            ForEach(viewModel.lists) { list in
                Button {
                    withAnimation {
                        viewModel.select(list.id)
                    }
                } label: {
                    if list.id == viewModel.selectedListID {
                        Label(list.name, systemImage: "checkmark")
                    } else {
                        Text(list.name)
                    }
                }
            }

            Divider()

            Button(action: viewModel.startCreatingList) {
                Label("Nueva lista…", systemImage: "plus")
            }

            Button(role: .destructive) {
                viewModel.showDeleteListAlert = true
            } label: {
                Label("Eliminar esta lista", systemImage: "trash")
            }
        } label: {
            HStack(spacing: 10) {
                Text(viewModel.selectedList?.name ?? "")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .accessibilityLabel("Lista: \(viewModel.selectedList?.name ?? ""). Toca para elegir otra lista")
    }

    // Película de la lista con su nota personal; tocarla abre el detalle
    private func row(for item: ListItem) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: item.movie) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appCardGray)
                        MoviePosterView(url: item.movie.posterURL, iconSize: 30)
                            .padding(4)
                    }
                    .frame(width: 76, height: 110)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.movie.title)
                            .font(.headline)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.trailing, 28)

                        if item.note.isEmpty {
                            Text(item.movie.overview)
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Tu nota")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.black.opacity(0.7))
                            Text(item.note)
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1.6)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                withAnimation {
                    viewModel.remove(item)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .padding(8)
            .accessibilityLabel("Quitar \(item.movie.title) de esta lista")
        }
    }

    // Botón de tres puntos para mostrar las siguientes películas
    private var loadMoreButton: some View {
        Button {
            withAnimation {
                viewModel.loadMore()
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .accessibilityLabel("Mostrar más películas de la lista")
    }

    // MARK: - Estados vacíos

    private var emptyListMessage: some View {
        VStack(spacing: 10) {
            Image(systemName: "film")
                .font(.system(size: 44))
                .foregroundColor(.gray)
            Text("Esta lista está vacía")
                .font(.headline)
                .foregroundColor(.black)
            Text("Abre cualquier película y toca \"Agregar a lista\" para guardarla aquí.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "list.bullet.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.gray)

            Text("Aún no tienes listas")
                .font(.title3.weight(.bold))
                .foregroundColor(.black)

            Text("Crea listas para ordenar tus películas a tu manera y escribe una nota sobre cada una.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: viewModel.startCreatingList) {
                Text("Crear mi primera lista")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.appCyan)
                    .cornerRadius(20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Con listas") {
    NavigationStack {
        ListsView(viewModel: ListsViewModel(listsService: MockListsService.sample))
    }
}

#Preview("Sin listas") {
    NavigationStack {
        ListsView(viewModel: ListsViewModel(listsService: MockListsService()))
    }
}
