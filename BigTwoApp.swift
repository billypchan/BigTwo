//
//  BigTwoApp.swift
//  Big Two — iOS remake of the Palm OS game.
//  Original © Chan Yiu Por Bill, 2006 · © Woo Kok Tong, 1999 · GPL
//

import SwiftUI

@main
struct BigTwoApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(.light)
        }
    }
}
