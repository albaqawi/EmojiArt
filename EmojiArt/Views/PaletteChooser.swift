//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 8/1/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    //we cannot set this chosenPalette to anything as this is init process and ObservedObj document is not init yet!
    
    //next line is the binding from one view to this one with same state name chosenPalette
    // we do not set it as it is set from somewhere else
    @Binding var chosenPalette: String
    
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, onDecrement: {
                self.chosenPalette = self.document.palette(before: self.chosenPalette)
            }, label: {EmptyView()})
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
        }
    .fixedSize(horizontal: true, vertical: false)
//no need to fix on appear no more on init
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        // clicking +/- on palette will do nothing on preview screen
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
