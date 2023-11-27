//
//  SearchBar.swift
//  ReadLog
//
//  Created by 유석원 on 11/20/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var fetchData: (String) -> Void
    
    var body: some View {
        HStack {
            HStack {
//                Image(systemName: "magnifyingglass")
                
                TextField("책 제목, 작가, 출판사", text: $text, onCommit: {
                    let request = "http://www.aladin.co.kr/ttb/api/ItemSearch.aspx?ttbkey=\(ApiKey.aladinKey)&Query=\(text)&QueryType=Keyword&MaxResults=10&start=1&SearchTarget=Book&output=js&Version=20131101"
                    fetchData(request)
                })
                .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                } else {
                    EmptyView()
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)
        }
        .padding(.horizontal)
    }
}

//#Preview {
//
//}
