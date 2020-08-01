//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 6/27/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import SwiftUI
import Combine
//ViewModel
class EmojiArtDocument: ObservableObject {
    private static let untitled = "EmojiArtDocument.Untitled"
           //we have a bug with property wrapers do not behave will with property observes
    @Published private var emojiArt: EmojiArt
    
    //now we can DECODE JSON we can init with the DECODER we did with init? on model
    // we need to create the following private var to ensure the sink live past the execution of the init with AnyCancellable?
    // now we ensure that this lives as long as this ViewModel lives
    private var autoSaveCancellable: AnyCancellable?
    private var fetchImageCancellable: AnyCancellable?
    
    init() {
        //this is a failable init so it can return nil so we have to add ?? and set to the empty model (start case)
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        //we need to go back and fetch the backgound image, the Document do not store image only url and must fetch again
        //A new fix for the bug of  property wrapers do not behave will with property observes
        autoSaveCancellable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
            print("json = \(emojiArt.json?.utf8 ?? "nil")")
            print("we are in the autoSaveCancellable block")
        }
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
    
    //change setbackgroundURL to computed var as backgroundURL to provide get and set to use in view, and assess if loading
    var backgoundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set{
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            // Every time there is a new request, cancel the old one
            fetchImageCancellable?.cancel()
            // Then make a new one... no need for condetional checking like before
            
            //the new publisher way of handling HTTP requests
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                //dataTaskPublisher returns a tuple data and failure response
                .map {
                    //we want to have our own publisher response that maps the data from dataTaskPublisher into UIImage
                    // where we know we want a UIImage for the BackgoundImage
                    data, URLResponse in UIImage(data: data)
            }
                //REMEMBER we need to do it on Main Queue as this is updating the backgound of app
                .receive(on: DispatchQueue.main)
                //next line is to ensure on sink or subscriber to publisher we do not handle errors
                .replaceError(with: nil)
                //we assigned it to our publisher declared above, assign only works if you have never as your error, link here or above on the spinner example
                .assign(to: \EmojiArtDocument.backgroundImage, on: self)
            
            //the previous manual way of handling HTTP requests
//            //manually go on network of UI thread to get image from netowrk
//            DispatchQueue.global(qos: .userInitiated).async {
//                if let imageData = try? Data(contentsOf: url) {
//                    //now this is a problem that will try to update UI on non-main thread
//                    DispatchQueue.main.async {
//                        //to avoid loading more than 1 background check the url used at start of the exec block is same,
//                        // if user drops more than 1 backgound we will not get impacted and cause conflicts
//                        //  this prevention allows us to show the latest url selected
//                        if url == self.emojiArt.backgroundURL {
//                            self.backgroundImage = UIImage(data: imageData)
//
//                        }
//                    }
//                }
//            }
        }
    }
}
