//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 6/28/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import Foundation

//model
//Encodable only works if all your var(s) are encodable so we needed to adjust the struct
struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    //made it Codable that inherests ENCODABLE/DECODABLE
    struct Emoji:Identifiable, Codable {
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
    // make model content into JSON
    var json:Data? {
        return try? JSONEncoder().encode(self)
    }
    // to bring it out of JSON, we use init? to make it a failable initilizer to get nil and know
    // I tried to make EmojiArt with JSON but I could not!
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            //set the model into the JSON structure
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    init() {
        //to restore init with default values as we lost that with declaring init?
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
}
