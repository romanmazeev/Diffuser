//
//  AppView.swift
//  Diffuser
//
//  Created by Roman Mazeev on 03/12/2022.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<Diffuser>

    var body: some View {
        NavigationSplitView {
            ArticlesListView(store: self.store.scope(state: \.articlesList, action: Diffuser.Action.articlesList))
        } detail: {
            IfLetStore(
                self.store.scope(state: \.articleDetails, action: Diffuser.Action.articleDetails),
                then: {
                    ArticleDetailsView(store: $0)
                },
                else: {
                    Text("Select an article")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            )
        } 
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(initialState: .init(), reducer: Diffuser()))
    }
}
#endif
