//
//  ArticleDetailsView.swift
//  Diffuser
//
//  Created by Roman Mazeev on 04/12/2022.
//

import SwiftUI
import ComposableArchitecture
import CachedAsyncImage

struct ArticleDetailsView: View {
    let store: StoreOf<ArticleDetails>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewStore.article.title)
                        .font(.largeTitle)
                        .bold()

                    if let description = viewStore.article.description {
                        Text(description)
                            .lineLimit(3)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }

                    imageView
                        .padding(.top)

                    Spacer()

                    if let content = viewStore.article.content {
                        Text(content)
                    }

                    Spacer()

                    HStack {
                        Text(viewStore.article.publishedAt, format: Date.FormatStyle(date: .numeric, time: .omitted))
                            .font(.footnote)
                        Text(viewStore.article.source.name)
                            .font(.footnote)
                        if let author = viewStore.article.author {
                            Text(author)
                                .font(.footnote)
                        }
                    }
                }
                .padding()
            }
        }
    }

    var imageView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            switch viewStore.imageState {
            case .notDiffused:
                createToDiffuseView(imageView: articleImageView)
            case .diffusionInProgress(let response):
                createDiffusionInProgressView(response: response)
            case .diffused(let cgImage):
                createToDiffuseView(imageView: createDiffusedView(image: cgImage))
            }
        }
    }

    private func createToDiffuseView(imageView: some View) -> some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack(alignment: .bottomTrailing) {
                imageView

                Button(action: {
                    viewStore.send(.onDiffuseButtonTap, animation: .default)
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                }
                .controlSize(.large)
                .padding()
            }
        }
    }

    private func createDiffusionInProgressView(response: DiffusionResponse) -> some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = response.image {
                    Image(image, scale: 1, label: Text("Diffusion in progress"))
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12, antialiased: true)
                } else {
                    articleImageView
                        .overlay(Material.regular)
                }
            }

            ProgressView("Loading...", value: response.progress)
                .padding()
        }
        .cornerRadius(12, antialiased: true)
    }

    private func createDiffusedView(image: CGImage) -> some View {
        Image(image, scale: 1, label: Text("Diffused image"))
            .resizable()
            .scaledToFit()
            .cornerRadius(12, antialiased: true)
    }

    private var articleImageView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            CachedAsyncImage(url: viewStore.article.urlToImage) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12, antialiased: true)
                case .failure(let error):
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text(error.localizedDescription)
                    }
                    .scaledToFill()
                @unknown default:
                    fatalError()
                }
            }
        }
    }
}

#if DEBUG
struct ArticleDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleDetailsView(store: Store(initialState: .init(article: .mocked, imageState: .notDiffused), reducer: ArticleDetails()))
    }
}
#endif

