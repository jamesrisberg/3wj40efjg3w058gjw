//
//  UIImageView+ImageRect.swift
//  StickerApp
//
//  Created by Nate Parrott on 9/6/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

import UIKit

extension UIImageView {
    var imageRect: CGRect {
        get {
            assert(contentMode == UIViewContentMode.ScaleAspectFit, "")
            let scale = min(1, min(self.bounds.size.width / image!.size.width, self.bounds.size.height / image!.size.height))
            let size = CGSizeMake(image!.size.width * scale, image!.size.height * scale)
            return CGRectMake((bounds.size.width - size.width)/2, (bounds.size.height - size.height)/2, size.width, size.height)
        }
    }
}
