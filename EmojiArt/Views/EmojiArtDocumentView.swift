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
                
                @State private var chosenPalette: String = ""

                private let defualtEmojiSize: CGFloat = 40
                
                @State private var steadyStatePanOffset: CGSize = .zero
                @GestureState private var gesturePanOffset: CGSize = .zero
                
                @State private var steadyStateZoomScale:CGFloat = 1.0
                @GestureState private var gestureZoomScale: CGFloat = 1.0
                
                private var zoomScale: CGFloat {
                    steadyStateZoomScale * gestureZoomScale
                }
                
                var body: some View {
                    VStack {
                        HStack {
                            //we send the projected value of chosenPalette found in $chosenPalette
                            PaletteChooser(document: document, chosenPalette: $chosenPalette)
                            ScrollView(.horizontal) {
                                HStack {
                                    //turn each char and turn in into array of strings
                                    // the correct way is to use id, \ is key path in Swift to identify another var, . means on current var and self is the palette
                                    ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                                        Text(emoji)
                                            .font(Font.system(size: self.defualtEmojiSize))
                                            .onDrag {
                                                // this is old Obj C and this is why we need to case
                                                // move from NS world to  Swift new world
                                                return NSItemProvider(object: emoji as NSString)
                                        }
                                    }
                                }
                                //to fix problem of at start we do not see the palette Category names
                                .onAppear { self.chosenPalette = self.document.defaultPalette }
                            }
                        }
                        .padding(.horizontal)
                        //we encapsulate all by GeometryReader as we need it to convert and know location of placement
                        GeometryReader { geometry in
                            ZStack {
                                Color.white.overlay(
                                    OptionalImage(uiImage: self.document.backgroundImage)
                                        .scaleEffect(self.zoomScale)
                                        .offset(self.panOffset)
                                )
                                    .gesture(self.doubleTapToZoom(in: geometry.size))
                                //Here is where we make a view to draw the dragged emojis on top of the backgound
                                //make sure emojis showup with background not before
                                if self.isLoading {
                                    //add a view modifier to allow for timer spinning animation
                                    Image(systemName: "hourglass").imageScale(.large).spinning()
                                } else {
                                    ForEach(self.document.emojis) { emoji in
                                        Text(emoji.text)
                                            .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                                            //                                        .font(self.font(for: emoji))
                                            .position(self.position(for: emoji, in: geometry.size))
                                    }
                                }
                            }
                                //Clips this view to its bounding rectangular frame - Zstack to not cover palette
                                .clipped()
                                //add the pan gesture
                                .gesture(self.panGesture())
                                //the pintch zoom on all doc
                                .gesture(self.zoomGesture())
                                //2 next modifers moved to here as they both apply to ZStack
                                .edgesIgnoringSafeArea([.horizontal, .bottom])
                                .onReceive(self.document.$backgroundImage) { image in
                                    self.zoomToFit(image, in: geometry.size)
                                }
                                //1st arg: what you want to drop we support 2 types public url images from internet and text characters(emojis), 2nd arg: this is a binding arg - letting us know when we drag over it, 3rd arg: function clousers
                                //location was explained as a bug is on global device coordinants so we need to convert it to View Coor System - CGPoint
                                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                                    // this is iOS Coor System (0,0) in upper left corner
                                    var location = geometry.convert(location, from: .global)
                                    // this is to convert from iOS Coor system to making (0,0) at center of image
                                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                                    // ajudt for pan gestures
                                   location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                                    //fixing the location with scaling effect
                                    location = CGPoint(x: location.x / self.zoomScale , y: location.y / self.zoomScale)
                                    return self.drop(providers: providers, at: location)
                            }
                        }
                    }
                }
                
                var isLoading: Bool {
                    // if both true then we are still loading
                    // backgroundURL we need to make a gettable, so we make backgroundURL as computed var with get and set
                    document.backgoundURL != nil && document.backgroundImage == nil
                }
                                
                private func doubleTapToZoom(in size: CGSize) -> some Gesture {
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation() { // used .linear(duration: 0.4) to slow the animation to understand behaviour
                                self.zoomToFit(self.document.backgroundImage, in: size)
                            }
                    }
                }
                //in lec 8 @ 1:05:35 explained why we need to handle this via the gesture and never directly
                //explained mofre on in out geasture parameter
                private func zoomGesture() -> some Gesture {
                    MagnificationGesture()
                    .updating($gestureZoomScale) { latestGestrureScale, gestureZoomScale, transaction in
                            gestureZoomScale = latestGestrureScale
                    }
                    .onEnded { finalGestureScale in
                        self.steadyStateZoomScale *= finalGestureScale
                    }
                }
                
                private var panOffset: CGSize {
                    (steadyStatePanOffset + gesturePanOffset) * zoomScale
                }
                
                private func panGesture() -> some Gesture {
                    DragGesture()
                        .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                            gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
                    }
                    .onEnded { finalDragGestureValue in
                        self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
                    }
                }
                
                
                // assisting function
                private func zoomToFit(_ image: UIImage?, in size: CGSize) {
                    if let image = image, image.size.width > 0 , image.size.height > 0 {
                        let hZoom = size.width / image.size.width
                        let vZoom = size.width / image.size.height
                        //which to use? we use smaller of 2 to ensure image is filly on screan in area provided of view
                        //adjust the pan gesture
                        self.steadyStatePanOffset = .zero //like CGSize.zero
                        self.steadyStateZoomScale = min(hZoom,vZoom)
                    }
                }
//               no need as we used now animatable
//                private func font(for emoji: EmojiArt.Emoji) -> Font {
//                    Font.system(size: emoji.fontSize * zoomScale)
//                }
                
                private func position(for emoji: EmojiArt.Emoji, in size: CGSize) ->  CGPoint {
                    var location = emoji.location
                    //I had emoji.location.[every apperence] on all following 3 lines and it messed things up, why? do not forget answers!
                    location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
                    location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
                    // adjust for pan gesture
                    location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
                    return location
                }
                //we made this drop func to be used for the backgound url image or for Emojis
                //so it will handle a drop from any app into this app, or drag from other view into this calling view
                private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
                    //if a url is found
                    var found = providers.loadFirstObject(ofType: URL.self) { url in
                        print("dropped \(url)")
                        self.document.backgoundURL = url
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
