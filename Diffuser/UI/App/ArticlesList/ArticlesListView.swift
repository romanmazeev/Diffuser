//
//  ArticlesListView.swift
//  Diffuser
//
//  Created by Roman Mazeev on 04/12/2022.
//

import SwiftUI
import ComposableArchitecture

struct ArticlesListView: View {
    let store: StoreOf<ArticlesList>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Group {
                if !viewStore.articles.isEmpty {
                    List(viewStore.articles, id: \.self, selection: viewStore.binding(\.$selectedArticle)) { article in
                        createArticleView(article: article)
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                viewStore.send(.onAppear, animation: .default)
            }
            .navigationTitle("Articles")
        }
    }

    private func createArticleView(article: Article) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.headline)
                .lineLimit(2)

            Text(article.source.name)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct ArticlesListView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesListView(store: Store(initialState: .init(), reducer: ArticlesList()))
    }
}
#endif
