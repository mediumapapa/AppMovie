import SwiftUI

// Ventana del botón "Agregar a lista" del detalle.
// Permite elegir en qué listas guardar la película, crear una lista nueva
// y escribir una pequeña sinopsis o nota personal.
struct AddToListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddToListViewModel

    init(viewModel: AddToListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                noteSection
                listsSection
                newListSection
            }
            .navigationTitle(viewModel.movie.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        viewModel.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            // Marcar o crear una lista ya guardó la película; al cerrar se guarda también la nota,
            // ya sea con "Listo" o deslizando la ventana hacia abajo.
            .onDisappear {
                viewModel.save()
            }
        }
    }

    private var noteSection: some View {
        Section {
            TextField("Escribe una pequeña sinopsis o un recuerdo de esta película", text: $viewModel.note, axis: .vertical)
                .lineLimit(3...6)
                .onChange(of: viewModel.note) {
                    viewModel.limitNote()
                    // La nota también se guarda mientras se escribe, así el detalle la muestra al cerrar
                    viewModel.save()
                }

            Text("\(viewModel.note.count)/\(AddToListViewModel.noteLimit)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } header: {
            Text("Tu nota personal")
        } footer: {
            Text("La nota se guarda junto con la película en las listas que marques. Los cambios se guardan solos.")
        }
    }

    private var listsSection: some View {
        Section {
            if let confirmation = viewModel.confirmationMessage {
                Label(confirmation, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)
            }

            if viewModel.lists.isEmpty {
                Text("Aún no tienes listas. Crea la primera aquí abajo.")
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.lists) { list in
                    Button {
                        viewModel.toggle(list)
                    } label: {
                        HStack {
                            Text(list.name)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: viewModel.isSelected(list) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(viewModel.isSelected(list) ? .black : .gray)
                        }
                    }
                    .accessibilityAddTraits(viewModel.isSelected(list) ? .isSelected : [])
                }
            }
        } header: {
            Text("Guardar en")
        }
    }

    private var newListSection: some View {
        Section {
            HStack {
                TextField("Nombre de la lista", text: $viewModel.newListName)
                    .submitLabel(.done)
                    .onSubmit(viewModel.createList)

                // .borderless: en un Form, un botón sin este estilo responde al toque en toda la fila,
                // incluido el campo de texto
                Button("Crear", action: viewModel.createList)
                    .buttonStyle(.borderless)
                    .fontWeight(.bold)
                    .disabled(viewModel.newListName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.red)
            }
        } header: {
            Text("Crear lista nueva")
        }
    }
}

#Preview {
    AddToListSheet(viewModel: AddToListViewModel(movie: Movie.sampleMovies[1], listsService: MockListsService.sample))
}
