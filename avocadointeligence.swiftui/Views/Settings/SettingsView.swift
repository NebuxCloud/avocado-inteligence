import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var llamaState: LlamaState
    @State private var showDownloadView = false
    @State private var showSelectModelView = false
    @State private var refreshView: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("model_selection", comment: "Model Selection Header"))) {
                    Button(action: {
                        showSelectModelView.toggle()
                    }) {
                        HStack {
                            Text(NSLocalizedString("selected_model", comment: "Label for selected model"))
                            Spacer()
                            Text(llamaState.selectedModel?.name ?? NSLocalizedString("none", comment: "No model selected"))
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showSelectModelView) {
                        SelectModelView(refreshView: $refreshView)
                    }
                    
                    Text(NSLocalizedString("model_selection_explanation", comment: "Explanation for model selection"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Section {
                    Button(action: {
                        showDownloadView.toggle()
                    }) {
                        Text(NSLocalizedString("download_new_models", comment: "Download new models button"))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showDownloadView) {
                        DownloadModelsView(refreshView: $refreshView)
                    }
                }
                
                Section(header: Text(NSLocalizedString("about", comment: "About section header"))) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avocado Intelligence")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("avocado_description", comment: "App description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                        
                        // Descripción simplificada sobre los beneficios de seleccionar modelos
                        Text(NSLocalizedString("model_benefit_description", comment: "Description of benefits of model selection"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    HStack {
                        Button(action: {
                            if let url = URL(string: NSLocalizedString("avocado_url", comment: "Avocado website URL")) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(NSLocalizedString("need_solution", comment: "Need your own solution button"))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 0)
                    
                    HStack {
                        Button(action: {
                            if let url = URL(string: NSLocalizedString("github_url", comment: "GitHub repo URL")) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(NSLocalizedString("open_source", comment: "Open source button"))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 0)
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: "Settings view title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
