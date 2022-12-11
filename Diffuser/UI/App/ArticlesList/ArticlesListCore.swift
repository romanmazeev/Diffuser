//
//  ArticlesListCore.swift
//  Diffuser
//
//  Created by Roman Mazeev on 04/12/2022.
//

import ComposableArchitecture

struct ArticlesList: ReducerProtocol {
    struct State: Equatable {
        var articles: [Article] = []
        @BindableState var selectedArticle: Article?
    }

    enum Action: BindableAction, Equatable {
        case onAppear
        case binding(BindingAction<State>)

        case getArticlesResponse(TaskResult<ArticleResponse>)
    }

    @Dependency(\.articlesService) var articlesService

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .task {
                    .getArticlesResponse(
                        await TaskResult {
                            try await self.articlesService.getArticles()
                        }
                    )
                }
            case .getArticlesResponse(let articlesResponse):
                do {
                    state.articles = try articlesResponse.value.articles
                } catch {
                    print(error)
                }
            default:
                break
            }

            return .none
        }
    }
}
