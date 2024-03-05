//
//  HomeScreenViewModel.swift
//  ScanIt
//
//  Created by Denys Hryshyn on 17.01.2024.
//

import Foundation
import FirebaseFirestore

class HomeScreenViewModel: ObservableObject {
    @Injected(\.firebaseService) var firebaseService
    
    @Published var networkMonitor = NetworkMonitor()
    
    // MARK: - Properties
    @Published var documents: [Document] = []
    @Published var selectedItems: Set<Document> = []
    @Published var selectedItem: Document? = nil

    @Published var searchString = ""
    @Published private var tapped = false
    @Published private var isShown = false
    @Published var activeSheet: ActiveContentViewSheet? = nil
    @Published var showDeleteAlert = false
    
    @Published var isSelectedMode: Bool = false
    @Published var isLoading: Bool = false
    
    var tintColor: String = "mainBlue"
    
    init() {
        Logger.print("init:\(#file)")
        self.fetchDocuments()
    }
    
    deinit {
        Logger.print("deinit:\(#file)")
    }
    
    // MARK: - Methods
    func fetchDocuments() {
        Task {
            do {
                let docs = try await firebaseService.fetchAllDocuments()
                let sortedDocs = docs.sorted(by: { Date(timeIntervalSince1970: $0.createdAt) > Date(timeIntervalSince1970: $1.createdAt) })
                await MainActor.run(body: {
                    documents = sortedDocs
                })
            } catch {
                print("❌ ERROR RETRIEVING DATA FROM FIRESTORE: \(error)")
            }
        }
    }
    
    func listenForNewDocs() {
        let docRef = Firestore.firestore().collection("Documents")
        
        // Listen to last child added
        docRef.order(by: "createdAt").addSnapshotListener({ (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                if (snapshot!.documents.count) > 0 {
                    self.fetchDocuments()
                }
            }
        })
    }
    
    func addNewDocument(itemName: String, docData: Data, totalAmount: Int, compIndex: Int) {
        Task {
            do {
                try await firebaseService.uploadFileToStorage(data: docData,
                                                              docName: itemName,
                                                              totalAmount: totalAmount)
            } catch {
                print("❌ ERROR SAVE DATA OF NEW DOCUMENT")
            }
        }
    }
    
    func deleteItems(items: [Document]) {
        items.forEach({ deleteItem(item: $0) })
        selectedItems.removeAll()
    }
    
    func deleteItem(item: Document) {
        Task {
            do {
                let id = item.id
                try await firebaseService.deleteFileBy(link: item.docURL, docID: id)
                fetchDocuments()
                print("✅ successfully removed")
            } catch {
                print("❌ FAILED TO DELETE DOCUMENT")
            }
        }
    }
    
    func deleteObject() {
        if !selectedItems.isEmpty {
            deleteItems(items: Array(selectedItems))
        } else if let item = selectedItem {
            deleteItem(item: item)
            self.selectedItem = nil
        }
    }
    
    func toggleSelection(for item: Document) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    func sharePdf() {
        DispatchQueue.main.async {
            FeedbackManager.light()
            self.activeSheet = .sharePDF
            self.tapped.toggle()
            self.isShown.toggle()
        }
    }
    
    func deleteRow(at offset: IndexSet) {
        let idsToDelete = offset.map { self.documents[$0]}
        _ = idsToDelete.compactMap { item in
            self.selectedItem = item
            self.showDeleteAlert.toggle()
        }
    }
}
