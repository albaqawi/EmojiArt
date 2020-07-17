//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 6/27/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import SwiftUI

// this is the VIEW
            struct EmojiArtDocumentView: View {
                @ObservedObject var document: EmojiArtDocument
                private let defualtEmojiSize: CGFloat = 40

                        var body: some View {
                            VStack {
                                ScrollView(.horizontal) {
                                         HStack {
                                             //turn each char and turn in into array of strings
                                             // the correct way is to use id, \ is key path in Swift to identify another var, . means on current var and self is the palette
                                             ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                                                 Text(emoji)
                                                     .font(Font.system(size: self.defualtEmojiSize))
                                                    .onDrag {
                                                        // this is old Obj C and this is why we need to case
                                                        // move from NS world to  Swift new world
                                                        return NSItemProvider(object: emoji as NSString)
                                                }
                                             }
                                         }
                                     }
                                     .padding(.horizontal)
                                //Rectangle().foregroundColor(.white).overlay(Image(self.document.backgroundImage))
                                GeometryReader { geometry in
                                    Color.white.overlay(
                                        //as we need to pass a view with conditions we use a Group
                                        Group {
                                            if self.document.backgroundImage != nil {
                                                Image(uiImage: self.document.backgroundImage!)
                                            }
                                        }
                                    )
                                        .edgesIgnoringSafeArea([.horizontal, .bottom])
                                        //1st arg: what you want to drop, 2nd arg: this is a binding arg - letting us know when we drag over it, 3rd arg: function clousers
                                        //location was explained as a bug is on global device coordinants so we need to convert it to View Coor System - CGPoint
                                        .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                                            var location = geometry.convert(location, from: .global)
                                            location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                                            return self.drop(providers: providers, at: location)
                                    }
                                    ForEach(self.document.emojis) { emoji in
                                        Text(emoji.text)
                                            .font(self.font(for: emoji))
                                            .position(self.position(for: emoji, in: geometry.size))
                                    }
                                }
                            }
                        }
                
                
                private func font(for emoji: EmojiArt.Emoji) -> Font {
                    Font.system(size: emoji.fontSize)
                }
                
                private func position(for emoji: EmojiArt.Emoji, in size: CGSize) ->  CGPoint {
                    CGPoint(x: emoji.location.x + size.width/2, y: emoji.location.y + size.height/2)
                }
                    
                private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
                    var found = providers.loadFirstObject(ofType: URL.self) { url in
                        print("dropped \(url)")
                        self.document.setBackgoundURL(url)
                    } //if we have a url then get the location, for dragging
                    if !found {
                        found = providers.loadObjects(ofType: String.self, using: { string in
                            self.document.addEmoji(string, at: location, size: self.defualtEmojiSize)
                        })
                    }
                    return found
                }
    }




//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

//extension String: Identifiable {
//    //public is non private in a library, this can solve String to be used in the ForEach! but this is wrong to use
//    public var id: String {
//        return self
//    }
//
//}
