import SwiftUI

struct AssistantView: View {
    @Binding var isMenuVisible: Bool
    @Binding var menuContent: AnyView?
    @State private var conversations: Conversations?
    @State private var selectedConversation: Conversation?
    @State private var isLoading = true
    @State private var newMessageText: String = "" // Estado para el mensaje nuevo
    @State private var isGeneratingMessage: Bool = false
    @EnvironmentObject var llamaState: LlamaState
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView(NSLocalizedString("loading_conversations", comment: "Loading conversations indicator"))
                        .padding()
                        .onAppear {
                            loadConversations()
                        }
                } else {
                    if let conversation = selectedConversation {
                        ConversationView(conversation: conversation)
                        
                        HStack(alignment: .bottom) {
                            CustomTextField(input: $newMessageText, isLoading: $isGeneratingMessage, send: sendMessage, stopLoading: stopMessage)
                        }
                        .padding(.horizontal)
                        .background(Color(UIColor.systemGray6))
                    } else {
                        Text(NSLocalizedString("select_or_create_conversation", comment: "Prompt to select or create a conversation"))
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
            }
            .navigationBarTitle(
                selectedConversation?.title.isEmpty == false ? selectedConversation!.title : NSLocalizedString("assistant_title", comment: "Title of the assistant view"),
                displayMode: .inline
            )
            .navigationBarItems(
                leading: Button(action: openMenu) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                },
                trailing: Button(action: {
                    addNewConversation()
                }) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
                .disabled(conversations?.conversations.isEmpty == false && selectedConversation?.messages.isEmpty == true)
            )
            .contentShape(Rectangle()) // Hace que el área de contenido sea táctil
            .onTapGesture {
                // Aquí cerramos el teclado al tocar fuera del TextField
                hideKeyboard()
            }
        }
    }

    private func loadConversations() {
        DispatchQueue.main.async {
            self.conversations = Conversations()
            self.conversations?.loadFromUserDefaults()
            if let lastConversation = self.conversations?.conversations.last {
                self.selectedConversation = lastConversation
            } else {
                self.addNewConversation() // Crear nueva conversación si no hay ninguna
            }
            self.isLoading = false
        }
    }
    
    private func addNewConversation() {
        conversations?.addEmptyConversation()
        selectedConversation = conversations?.conversations.last
    }
    
    private func openMenu() {
        if let conversations = conversations {
            menuContent = AnyView(
                AssistantMenuContent(
                    selectedConversation: $selectedConversation,
                    conversations: $conversations
                )
            )
            isMenuVisible = true
        }
    }
    
    private func sendMessage() {
        isGeneratingMessage = true
        selectedConversation?.addMessage(content: newMessageText, role: .user)
        
        let chatCompletion = LlamaChatCompletion(llamaState: llamaState)
        
        // Crear el mensaje inicial del asistente vacío y añadirlo a la conversación
        let assistantMsg = ChatMessage(content: "", role: .assistant)
        assistantMsg.isLoading = true

        selectedConversation?.appendMessage(assistantMsg)
        
        // Resetear el campo de texto
        newMessageText = ""
        
        // Ejecutar en una tarea asíncrona con MainActor
        Task { @MainActor in
            await chatCompletion.chatCompletion(
                messages: selectedConversation?.messages ?? [],
                resultHandler: { token in
                    // Actualizar el contenido en tiempo real eliminando y reinsertando el mensaje
                    if let assistantIndex = selectedConversation?.messages.firstIndex(where: { $0.id == assistantMsg.id }) {
                        selectedConversation?.messages.remove(at: assistantIndex)
                        assistantMsg.content += token
                        assistantMsg.isLoading = true
                        selectedConversation?.messages.insert(assistantMsg, at: assistantIndex)
                    }
                },
                onComplete: {
                    assistantMsg.isLoading = false
                    isGeneratingMessage = false
                    conversations?.saveToUserDefaults()
                }
            )
        }
    }
    
    private func stopMessage() {
        // Implementar la lógica para detener la generación de mensajes en llamaState si es soportado
        Task { @MainActor in
            await llamaState.stop()
            isGeneratingMessage = false
        }
    }
}

// Extensión para ocultar el teclado
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
