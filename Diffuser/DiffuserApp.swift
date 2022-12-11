//
//  DiffuserApp.swift
//  Diffuser
//
//  Created by Roman Mazeev on 03/12/2022.
//

import SwiftUI

@main
struct DiffuserApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .init(initialState: .init(), reducer: Diffuser()))
        }
    }
}
