//
//  ArticleDetailsCore.swift
//  Diffuser
//
//  Created by Roman Mazeev on 04/12/2022.
//

import ComposableArchitecture
import CoreImage
import SwiftUI

struct ArticleDetails: ReducerProtocol {
    struct State: Equatable {
        enum ImageState: Equatable {
            case notDiffused

            /// Progress from 0 to 1
            case diffusionInProgress(DiffusionResponse)
            case diffused(CGImage)
        }

        let article: Article
        var imageState: ImageState
    }

    enum Action {
        case onDiffuseButtonTap
        case onReceiveDiffusionResponse(TaskResult<DiffusionResponse>)
    }

    @Dependency(\.diffusionService) var diffusionService

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onDiffuseButtonTap:
                state.imageState = .diffusionInProgress(.init(progress: 0, image: nil))

                return .run { [title = state.article.title] send in
                    for try await response in diffusionService.startTask(title) {
                        await send(.onReceiveDiffusionResponse(.success(.init(progress: response))))
                    }
                }
            case let .onReceiveDiffusionResponse(.success(response)):
                if response.progress >= 1, let image = response.image {
                    state.imageState = .diffused(image)
                } else {
                    state.imageState = .diffusionInProgress(response)
                }
            case let .onReceiveDiffusionResponse(.failure(error)):
                print(error.localizedDescription)
            }

            return .none
        }
    }
}
