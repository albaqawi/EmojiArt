//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 6/27/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import SwiftUI
//ViewModel
class EmojiArtDocument: ObservableObject {
    private static let untitled = "EmojiArtDocument.Untitled"
   // @Published         //we have a bug with property wrapers do not behave will with property observes
    private var emojiArt: EmojiArt = EmojiArt() {
        //willSet is the workaround
        willSet {
            objectWillChange.send()
        }
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
            print("json = \(emojiArt.json?.utf8 ?? "nil")")
        }
    }
    
    //now we can DECODE JSON we can init with the DECODER we did with init? on model
    init() {
        //this is a failable init so it can return nil so we have to add ?? and set to the empty model (start case)
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        //we need to go back and fetch the backgound image, the Document do not store image only url and must fetch again
        fetchBackgroundImageData()
    }
    
    //only model fitches images from internet, we must publish to be tracked in ViewModel
    @Published private(set) var backgroundImage: UIImage?
    
    //the model is private so we need to make this read version of emojiArt model
    //this will return all the emojis in our array
    // the { } acts like the Get
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    
    static let palette : String = "💻🤪😘😔😡😃🥶😱🥵😎🤩🥳🧀🥨"
    
    // MARK: - Intents
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    //we extedned the Collection a protocol that Array impliments with 1st index matching to be able to control
    //collection content
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func setBackgoundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            //manually go on network of UI thread to get image from netowrk
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    //now this is a problem that will try to update UI on non-main thread
                    DispatchQueue.main.async {
                        //to avoid loading more than 1 background check the url used at start of the exec block is same,
                        // if user drops more than 1 backgound we will not get impacted and cause conflicts
                        //  this prevention allows us to show the latest url selected
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                            
                        }
                    }
                }
            }
        }
    }
}
