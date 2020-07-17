//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 6/28/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import Foundation

//model
struct EmojiArt {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji:Identifiable {
        let text: String
        var x: Int //offset from center
        var y: Int //offset from center
        var size: Int
        var id: Int      // UUID() -> //this is overkill
       
        //we use an private init so no one can hyjack from insteration
        fileprivate init(text: String, x: Int,y: Int, size: Int,id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
}
