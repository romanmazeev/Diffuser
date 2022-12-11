//
//  AppCore.swift
//  Diffuser
//
//  Created by Roman Mazeev on 03/12/2022.
//

import ComposableArchitecture
import CoreImage

struct Diffuser: ReducerProtocol {
    struct State {
        var articlesList: ArticlesList.State = .init()
        var articleDetails: ArticleDetails.State?
    }

    enum Action {
        case articlesList(ArticlesList.Action)
        case articleDetails(ArticleDetails.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.articlesList, action: /Action.articlesList) {
            ArticlesList()
        }
    
        Reduce { state, action in
            switch action {
            case .articlesList(.binding(\.$selectedArticle)):
                if let article = state.articlesList.selectedArticle {
                    state.articleDetails = .init(article: article, imageState: .notDiffused)
                } else {
                    state.articleDetails = nil
                }
            default:
                break
            }

            return .none
        }
        .ifLet(\.articleDetails, action: /Action.articleDetails) {
            ArticleDetails()
        }
    }
}
