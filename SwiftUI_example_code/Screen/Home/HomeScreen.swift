//
//  HomeScreen.swift
//  ScanIt
//
//  Created by Denys Hryshyn on 17.01.2024.
//

import SwiftUI
import NavigationStack
import PopupView

protocol HomeScreenRouter: AnyObject {
    func goToDetailScreen(item: Document) -> DetailPDFView
    func goToProfileScreen() -> ProfileScreen
}

struct HomeScreen: View {
    //MARK: - @State variables
    @State var router: HomeScreenRouter?
    @StateObject var viewModel: HomeScreenViewModel = HomeScreenViewModel()
    
    // MARK: - ObservedObjects
    @ObservedObject var searchBar: SearchBar = SearchBar()
    
    // MARK: - Properties
    var body: some View {
        NavigationStackView {
            SearchNavigation(text: $viewModel.searchString, largeDisplay: false) {
                ZStack {
                    Color.systemGroupedBackground
                    VStack(alignment: .leading) {
                        //check if contents isn't empty
                        if !viewModel.documents.isEmpty {
                            // display contents of file
                            if viewModel.documents.isEmpty {
                                NewStarterView()
                                //EmptyView()
                                Color.clear
                            } else {
                                List {
                                    Section(header:
                                                VStack(alignment: .leading, spacing: 8) {
                                        Text("Unterlagen")
                                            .font(Font.custom("SF UI Text", size: 20).weight(.medium))
                                            .foregroundColor(.white)
                                        Text("Tippen Sie auf ein Element und halten Sie es gedrückt, um weitere Optionen anzuzeigen")
                                            .font(.caption)
                                    }) {
                                        ForEach(self.viewModel.documents.filter { self.viewModel.searchString.isEmpty || $0.docName.localizedStandardContains(self.viewModel.searchString)}) { item in
                                            DocumentsListRowView(item: item,
                                                                 isSelected: viewModel.selectedItems.contains(item),
                                                                 selectedItems: $viewModel.selectedItems,
                                                                 isLoading: $viewModel.isLoading,
                                                                 router: router){
                                                viewModel.toggleSelection(for: item)
                                            } deleteItemPressed: {
                                                viewModel.deleteItem(item: item)
                                            }
                                        }
                                        .onDelete(perform: self.viewModel.deleteRow(at:))
                                    }
                                }
                                .listStyle(InsetGroupedListStyle())
                                
                                if !viewModel.selectedItems.isEmpty {
                                    HStack {
                                        Button(action: {
                                            viewModel.showDeleteAlert.toggle()
                                        }) {
                                            HStack(spacing: 10) {
                                                Text("Löschen")
                                                    .font(
                                                        Font.custom("SF UI Text", size: 20)
                                                            .weight(.medium))
                                                
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 24, height: 24)
                                                    
                                                    Text("\(viewModel.selectedItems.count)")
                                                        .font(
                                                            Font.custom("SF UI Text", size: 14)
                                                                .weight(.semibold)
                                                        )
                                                        .foregroundColor(Color(red: 0.95, green: 0.24, blue: 0.24))
                                                }
                                            }
                                            .foregroundColor(Color.white)
                                            .frame(width: 150, height: 48)
                                            .background(Color(red: 0.95, green: 0.24, blue: 0.24))
                                            .cornerRadius(4)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { viewModel.sharePdf() }) {
                                            HStack(spacing: 10) {
                                                Text("Teilen")
                                                    .font(
                                                        Font.custom("SF UI Text", size: 20)
                                                            .weight(.medium))
                                                
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 24, height: 24)
                                                    
                                                    Text("\(viewModel.selectedItems.count)")
                                                        .font(
                                                            Font.custom("SF UI Text", size: 14)
                                                                .weight(.semibold)
                                                        )
                                                        .foregroundColor(Color("mainBlue"))
                                                }
                                            }
                                            .foregroundColor(Color.white)
                                            .frame(width: 150, height: 48)
                                            .background(Color("mainBlue"))
                                            .cornerRadius(4)
                                        }
                                    }
                                    .padding()
                                    .padding(.bottom)
                                }
                            }
                        } else {
                            NewStarterView()
                            Color.clear
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        PushView(destination: router!.goToProfileScreen()) {
                            Image(systemName: "person.circle")
                                .frame(width: 30, height: 30)
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.white)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(LoadingView(show: $viewModel.isLoading))
        //.overlay(NoInternetConnectionView(hide: $viewModel.networkMonitor.isConnected))
        //.noInternetConnectionToast(isHide: $viewModel.networkMonitor.isConnected, text: Text(""))
        
        
        .popup(isPresented: $viewModel.networkMonitor.isConnected.not, view: {
            NoInternetConnectionView()
        }, customize: {
            $0
                    .isOpaque(true)
                    .position(.center)
                    .animation(.spring())
                    .closeOnTapOutside(false)
                    .dragToDismiss(false)
                    .closeOnTap(false)
                    .backgroundColor(Color(red: 0.13, green: 0.15, blue: 0.2))
        })
        
        // On appear code
        .onAppear {
            viewModel.fetchDocuments()
            viewModel.listenForNewDocs()
        }
        // sheet code
        // make sure to conform to identifiable
        .fullScreenCover(item: $viewModel.activeSheet, onDismiss: {
            self.viewModel.activeSheet = nil
        }) { item in
            
            switch item {
            case .sharePDF:
                ShareSheetView(activityItems: self.viewModel.selectedItems.map { URL(string: $0.docURL)! })
            default:
                EmptyView()
            }
            
        }
        .alert(isPresented: $viewModel.showDeleteAlert) {
            return Alert(title: Text("Sind Sie sicher, dass Sie die Elemente löschen möchten?"), primaryButton: .default(Text("Zurückweisen")), secondaryButton: .destructive(Text("Löschen"), action: {
                self.viewModel.deleteObject()
            }))
        }
    }
}
