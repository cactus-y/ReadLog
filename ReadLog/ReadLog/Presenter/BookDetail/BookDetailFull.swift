//
//  BookDetailFull.swift
//  ReadLog
//
//  Created by 이만 on 2023/11/21.
//

import SwiftUI
import CoreData

struct BookDetailFull: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ReadingTrackerViewModel
    @State private var pagesReadInput: String = ""
    @FocusState private var isInputActive: Bool
    private var bookInfo: BookInfo
    let memoDateFormatter: DateFormatter = Date.yyyyMdFormatter
    let isbn: String
    
    init(_ isbn: String) {
        // book1
        let newBook1 = BookInfo(context: PersistenceController.shared.container.viewContext)
        newBook1.isbn = "newBook3"
        newBook1.author = "Kim"
        newBook1.pagecount = 400
        newBook1.readList = nil
        if let bookCoverImage = UIImage(named: "bookExample"), let imageData = bookCoverImage.pngData() {
                newBook1.image = imageData
            }
        self.isbn = isbn
        self.bookInfo = newBook1
        self._viewModel = StateObject(wrappedValue: ReadingTrackerViewModel(context: PersistenceController.shared.container.viewContext, totalPage: Int(newBook1.pagecount)))
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    displayBook(isbn: self.isbn)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 40, trailing: 0))
                    progressBar(value: viewModel.progressPercentage)
                    Spacer(minLength: 20)
                    trackingCircles(viewModel: self.viewModel)
                    bookNotes(memos: Memo.sampleData)
                }
                pageInput
            }
            .padding(.horizontal)
            .background(Color("backgroundColor"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action:{
                        self.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.primary)
                    }
                }
                
                //TODO: When the button is pressed, add book into readList
                ToolbarItem(placement: .topBarTrailing){
                    Button("완독"){
                    }
                    .body1(Color.primary)
                }
            }
        }
        .onAppear(perform: {
            viewModel.setDailyProgress(isbn: "newBook3")
        })
    }
}
// function
private extension BookDetailFull {
    func fetchBookInfo(isbn: String) -> BookInfo? {
        let fetchRequest: NSFetchRequest<BookInfo>
        
        fetchRequest = BookInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "isbn LIKE %@", isbn)
        
        do {
            let object = try viewContext.fetch(fetchRequest)
            return object.first
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved Error\(nsError)")
        }
    }
    
    func fetchAllBookNotes(isbn: String) -> [ReadLog]{
        let fetchRequest: NSFetchRequest<ReadLog>
        
        fetchRequest = ReadLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K LIKE %@",#keyPath(ReadLog.book.isbn), isbn)
        
        do {
            let objects = try viewContext.fetch(fetchRequest)
            return objects
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved Error\(nsError)")
        }
    }
}

// MARK: - 책 정보 뷰
private extension BookDetailFull {
    @ViewBuilder
    func displayBook(isbn: String) -> some View {
        if let book = fetchBookInfo(isbn: isbn) {
            VStack {
                HStack{
                    if let imageData = book.image, let uiImage = UIImage(data:imageData){
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 140)
                            .background(Color.white)
                    }else{
                        Image(systemName: "book")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 140)
                            .background(Color.white)
                    }
                    VStack(alignment: .leading){
                        Text(book.title ?? "Unknown Title")
                            .title(Color.primary)
                            .padding(.bottom,10)
                        Text(book.author ?? "Unknown Author")
                            .body2(Color.primary)
                            .padding(.bottom,2)
                        Text(book.publisher ?? "Unknown Publisher")
                            .body2(Color.primary)
                            .padding(.bottom,2)
                    }
                    .padding(.leading,10)
                }
                .frame(width: 323.0, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius:10)
                    .stroke(Color("gray"), lineWidth: 1)
                )
            }
        }else{
            Text("Book not found").title(Color.primary)
        }
    }
}

// MARK: - progress view
private extension BookDetailFull {
    func progressBar(value: Double) -> some View {
        let thickness: CGFloat = 15
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: thickness)
                    .opacity(0.3)
                    .foregroundColor(Color("gray"))
                
                Rectangle().frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: thickness)
                    .foregroundColor(Color("lightBlue"))
                    .animation(.linear, value: value)
            }
            .clipShape(RoundedRectangle(cornerRadius: 45))
        }
        .frame(height: 15)
    }
}

// MARK: - Daily Tracking view
private extension BookDetailFull {
    struct trackingCircles: View {
        @StateObject var viewModel: ReadingTrackerViewModel
        var body: some View {
            HStack {
                ForEach(viewModel.dailyProgress) { progress in
                    Circle()
                        .fill(progress.pagesRead > 0 ? Color("lightBlue") : Color("gray"))
                        .frame(width: 45, height: 45)
                        .overlay(Text("\(progress.pagesRead)p"))
                        .body3(Color.primary)
                }
            }
        }
    }
}

//MARK: - Book Note view
private extension BookDetailFull {
    func bookNotes(memos: [Memo]) -> some View {
        LazyVStack {
            ForEach(memos){memo in
                Divider()
                VStack(alignment: .leading, spacing:10) {
                    HStack {
                        Text(memoDateFormatter.string(from: memo.date))
                            .bodyDefault(Color("gray"))
                            .foregroundColor(.secondary)
                        Spacer()
                        NoteLabel(type: .constant(.impressive))
                    }
                    Text(memo.content)
                        .bodyDefault(Color.primary)
                }
                .padding(.vertical, 10)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - today page input view
private extension BookDetailFull {
    var pageInput: some View {
        HStack {
            Text("어디까지 읽으셨나요?")
                .body1(Color.primary)
            Spacer()
            TextField("페이지 번호...", text: $pagesReadInput)
                .frame(width:120, height: 37)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(isInputActive ? .black : Color("gray")).body2(Color.primary)
                .focused($isInputActive)
        }
        .padding()
        .frame(height:47)
        .background(Color("lightBlue"),in: RoundedRectangle(cornerRadius: 10))
        .onSubmit {
            if let newPageRead = Int(pagesReadInput), newPageRead > viewModel.lastPageRead {
                viewModel.addDailyProgress(newPageRead: newPageRead, bookInfo: self.bookInfo)
                pagesReadInput = "" // Clear the input field
            }
        }
        
    }
}
#Preview {
    BookDetailFull("newBook3")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
