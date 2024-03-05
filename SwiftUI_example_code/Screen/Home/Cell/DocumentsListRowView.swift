//
//  DocumentsListRowView.swift
//  ScanIt
//
//  Created by Denys Hryshyn on 29.01.2024.
//

import SwiftUI
import LocalAuthentication
import PDFKit
import NavigationStack

struct DocumentsListRowView: View {
    
    // MARK: - Properties
    var item: Document
    
    var isSelected: Bool
    
    @Binding var selectedItems: Set<Document>
    @Binding var isLoading: Bool
    
    var router: HomeScreenRouter?
    
    let toggleSelection: () -> Void
    let deleteItemPressed: () -> Void
    
    @State private var isDisabled = false
    @State private var url = ""
    @State private var uiImages = [UIImage]()
    @State private var showAlert = false
    @State private var showDeleteAlert = false
    @State private var showSheet = false
    @State private var alertMessage: LocalizedStringKey = ""
    @State private var alertTitle: LocalizedStringKey = ""
    @State private var activeSheet: ActiveSheetForDetails? = nil
    @State private var alertContext: ActiveAlertSheet = .error
    @State private var isFile = false
    @State var selectedItem: Document?
    @State private var selectedIndex: Int = 0
    @State private var docImg: UIImage = UIImage()
    
    var body: some View {
        if selectedItems.isEmpty {
            PushView(destination: Group {
                if selectedItems.isEmpty {
                    router?.goToDetailScreen(item: item)
                }
            }, isActive: $isDisabled, label: {
                HStack {
                    Image(isSelected ? "circleOn": "circleOff")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .onTapGesture {
                            toggleSelection()
                        }
                    
                    Image(uiImage: docImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 39)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(self.item.docName)
                                .font(.body)
                                .lineLimit(1)
                        }
                        Text(self.item.convertedDateToString)
                            .font(Font.custom("SF UI Text", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button(action: {
                        isLoading = true
                        DispatchQueue.global().async {
                            self.uiImages = self.getImagesAndPath()
                            self.selectedItem = self.item
                            DispatchQueue.main.async {
                                isLoading = false
                                self.activeSheet = .editSheet(images: self.uiImages, url: self.url, item: self.item)
                            }
                        }
                    }) {
                        HStack {
                            SFSymbol.pencil
                            Text("Umbenennen")
                        }
                    }
                    
                    Button(action: {
                        DispatchQueue.global().async {
                            self.selectedItem = self.item
                            self.getUrl()
                        }
                    }) {
                        HStack {
                            SFSymbol.share
                            Text("Teilen")
                        }.foregroundColor(.yellow)
                    }
                    
                    Button(action: {
                        isLoading = true
                        DispatchQueue.global().async {
                            self.uiImages = self.getImagesAndPath()
                            self.selectedItem = self.item
                            DispatchQueue.main.async {
                                isLoading = false
                                self.activeSheet = .editSheet(images: self.uiImages, url: self.url, item: self.item)
                            }
                        }
                        
                    }) {
                        HStack {
                            SFSymbol.pencilCircle
                            Text("Bearbeiten")
                        }
                    }
                    
                    Button(action: {
                        self.selectedItem = self.item
                        self.alertContext = .notice
                        self.showAlert.toggle()
                    }) {
                        HStack {
                            SFSymbol.trash
                            Text("Löschen")
                        }.foregroundColor(.red)
                    }
                }
            })
            .onAppear {
                setDocImage()
            }
            
            .alert(isPresented: $showAlert) {
                
                if alertContext == .notice {
                    return Alert(title: Text("Sind Sie sicher, dass Sie das Element löschen möchten?"), primaryButton: .default(Text("Zurückweisen")), secondaryButton: .destructive(Text("Löschen"), action: {
                        self.deleteObject()
                    }))
                } else {
                    return Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: .cancel(Text("Zurückweisen"), action: {
                        print("retry")
                    }))
                }
            }
            
            
            .sheet(item: $activeSheet, onDismiss: { self.activeSheet = nil }) { state in
                switch state {
                case .shareSheet(let url):
                    ShareSheetView(activityItems: [URL(string: url)!])
                        .onAppear {
                            print("/////")
                            print(self.url)
                            print("/////")
                            
                        }
                case .editSheet(let images, let url, let item):
                    EditPDFMainView(pdfName: self.item.docName, mainPages: images, url: url, item: item)
                default:
                    EmptyView()
                }
            }
            
        } else {
            HStack {
                Image(isSelected ? "circleOn": "circleOff")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        toggleSelection()
                    }
                
                Image(uiImage: docImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 39)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(self.item.docName)
                            .font(.body)
                            .lineLimit(1)
                    }
                    Text(self.item.convertedDateToString)
                        .font(Font.custom("SF UI Text", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
            .contentShape(Rectangle())
            .onAppear {
                setDocImage()
            }
            
            .alert(isPresented: $showAlert) {
                
                if alertContext == .notice {
                    return Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), primaryButton: .default(Text("Zurückweisen")), secondaryButton: .destructive(Text("Löschen"), action: {
                        self.deleteObject()
                    }))
                } else {
                    return Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: .cancel(Text("Zurückweisen"), action: {
                        print("retry")
                    }))
                }
            }
            
            
            .sheet(item: $activeSheet, onDismiss: { self.activeSheet = nil }) { state in
                switch state {
                case .shareSheet(let url):
                    ShareSheetView(activityItems: [URL(string: url)!])
                        .onAppear {
                            print("/////")
                            print(self.url)
                            print("/////")
                            
                        }
                case .editSheet(let images, let url, let item):
                    EditPDFMainView(pdfName: self.item.docName, mainPages: images, url: url, item: item)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    
    // MARK: - Functions
    func deleteObject() {
        deleteItemPressed()
    }
    
    private func setDocImage() {
        DispatchQueue.global().async {
            if let docImg = drawPDFfromURL(url: URL(string: item.docURL)!) {
                DispatchQueue.main.async {
                    self.docImg = docImg
                }
            }
        }
    }
    
    private func drawPDFfromURL(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            ctx.cgContext.drawPDFPage(page)
        }
        return img
    }
    
    func getImagesAndPath() -> [UIImage]{
        var imgs = [UIImage]()
        
        // now to extract imgs from pdf
        if let pdf = CGPDFDocument(URL(string: item.docURL)! as CFURL) {
            let pageCount = pdf.numberOfPages
            
            for i in 0 ... pageCount {
                autoreleasepool {
                    guard let page = pdf.page(at: i) else { return }
                    let pageRect = page.getBoxRect(.mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let image = renderer.image { ctx in
                        UIColor.white.set()
                        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                        ctx.fill(pageRect)
                        ctx.cgContext.drawPDFPage(page)
                    }
                    
                    /// just to test theory
                    print("bytes without downsampling: ",image.pngData()!.count)
                    print("bytes with downsampling: ",image.downSampleImage().pngData()!.count)
                    print("bytes with jpeg compression: ", image.downSampleImage().jpegData(compressionQuality: 1)!.count)
                    
                    imgs.append(image.downSampleImage())
                }
            }
            
            if pageCount == imgs.count {
                DispatchQueue.main.async {
                    self.url = item.docURL
                }
                return imgs
            }
            
        } else {
            self.alertContext = .error
            self.alertTitle = "Fehler"
            self.alertMessage = "Es konnten keine Bilder aus der PDF-Datei abgerufen werden :("
            self.showAlert.toggle()
        }
        return imgs
    }
    
    func getUrl() {
        if selectedItem != nil {
            url = item.docURL
            DispatchQueue.main.async {
                if self.url != "" {
                    self.activeSheet = .shareSheet(url: self.url)
                }
            }
        }
    }
}
