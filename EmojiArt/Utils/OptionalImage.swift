//
//  optionalImage.swift
//  EmojiArt
//
//  Created by Ahmed Albaqawi on 7/22/20.
//  Copyright © 2020 Ahmed Albaqawi. All rights reserved.
//

import SwiftUI

//new we can use it in diff projects like arr.firstIndexOf

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        //as we need to pass a view with conditions we use a Group, overlay expects a View returned not logic or conditions
        // we cannot use ZStack as we need to size the image to the provided space to show background so using overlay w/backgound allows to use all the size to fit image
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
