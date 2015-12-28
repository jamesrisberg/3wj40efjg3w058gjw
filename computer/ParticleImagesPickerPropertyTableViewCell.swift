//
//  ParticlesPickerPropertyTableViewCell.swift
//  computer
//
//  Created by Nate Parrott on 12/28/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class ParticlesPickerPropertyTableViewCell: PropertyViewTableCell {
    override func setup() {
        super.setup()
        let viewSnapshots = self.editor.canvas.snapshotsOfAllDrawables()
        cells = (0..<4).map({
            i in
            let cell = ImageCell()
            cell.viewSnapshots = viewSnapshots
            cell.onImageChanged = {
                [weak self]
                imageOpt in
                var images = (self!.value as? [UIImage]) ?? []
                if let image = imageOpt {
                    if i < images.count {
                        images[i] = image
                    } else {
                        images.append(image)
                    }
                } else {
                    if i < images.count {
                        images.removeAtIndex(i)
                    }
                }
                self!.saveValue(images)
            }
            return cell
        })
        var constraints = [NSLayoutConstraint]()
        var prevCell: ImageCell?
        for cell in cells {
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.setup()
            contentView.addSubview(cell)
            constraints.append(cell.heightAnchor.constraintEqualToAnchor(self.heightAnchor))
            constraints.append(cell.topAnchor.constraintEqualToAnchor(self.topAnchor))
            if let prev = prevCell {
                constraints.append(cell.widthAnchor.constraintEqualToAnchor(prev.widthAnchor))
                constraints.append(cell.leadingAnchor.constraintEqualToAnchor(prev.trailingAnchor, constant: 12))
            } else {
                // this is the first cell:
                constraints.append(cell.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor, constant: 12))
            }
            prevCell = cell
        }
        constraints.append(self.trailingAnchor.constraintEqualToAnchor(prevCell!.trailingAnchor, constant: 12))
        addConstraints(constraints)
    }
    
    var cells: [ImageCell]!
    
    override func reloadValue() {
        super.reloadValue()
        
        let images = (self.value as? [UIImage]) ?? []
        for i in 0..<cells.count {
            let cell = cells[i]
            let image: UIImage? = i < images.count ? images[i] : nil
            cell.image = image
        }
    }
    
    class ImageCell: UIView {
        // MARK: External
        var image: UIImage? {
            didSet {
                imageView.image = image
                cutButton.enabled = (image != nil)
                clearButton.enabled = (image != nil)
            }
        }
        var onImageChanged: (UIImage? -> ())?
        
        var viewSnapshots = [UIImage]()
        
        func setup() {
            for v in [imageView, clearButton, cutButton] {
                addSubview(v)
                v.translatesAutoresizingMaskIntoConstraints = false
            }
            imageView.contentMode = .ScaleAspectFit
            imageView.backgroundColor = UIColor(white: 1, alpha: 0.4)
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 6
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pickImage"))
            
            clearButton.setImage(UIImage(named: "ParticleImageDelete"), forState: .Normal)
            clearButton.addTarget(self, action: "clear", forControlEvents: .TouchUpInside)
            
            cutButton.setImage(UIImage(named: "ParticleImageCut"), forState: .Normal)
            cutButton.addTarget(self, action: "cut", forControlEvents: .TouchUpInside)
            
            addConstraints([
                imageView.widthAnchor.constraintEqualToAnchor(imageView.heightAnchor),
                imageView.widthAnchor.constraintEqualToAnchor(self.widthAnchor),
                self.centerXAnchor.constraintEqualToAnchor(imageView.centerXAnchor),
                self.centerYAnchor.constraintEqualToAnchor(imageView.centerYAnchor),
                clearButton.centerXAnchor.constraintEqualToAnchor(imageView.centerXAnchor),
                cutButton.centerXAnchor.constraintEqualToAnchor(imageView.centerXAnchor),
                clearButton.topAnchor.constraintEqualToAnchor(imageView.bottomAnchor),
                cutButton.bottomAnchor.constraintEqualToAnchor(imageView.topAnchor),
                clearButton.widthAnchor.constraintEqualToConstant(40),
                clearButton.heightAnchor.constraintEqualToConstant(40),
                cutButton.widthAnchor.constraintEqualToConstant(40),
                cutButton.heightAnchor.constraintEqualToConstant(40)
                ])
            
            let placeholderIcon = UIImageView(image: UIImage(named: "Camera"))
            placeholderIcon.alpha = 0.5
            placeholderIcon.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(placeholderIcon, atIndex: 0)
            addConstraints([
                placeholderIcon.centerXAnchor.constraintEqualToAnchor(imageView.centerXAnchor),
                placeholderIcon.centerYAnchor.constraintEqualToAnchor(imageView.centerYAnchor)
                ])
        }
        
        // MARK: Internal
        let imageView = UIImageView()
        let clearButton = UIButton()
        let cutButton = UIButton()
        
        func pickImage() {
            let picker = CMPhotoPicker.photoPicker() as! CMPhotoPicker
            picker.viewSnapshots = viewSnapshots
            picker.imageCallback = {
                [weak self]
                (imageOpt: UIImage?) in
                if let image = imageOpt, let s = self {
                    s.changeImage(image.resizedWithMaxDimension(1200))
                }
            }
            picker.present()
        }
        
        func clear() {
            changeImage(nil)
        }
        
        func cut() {
            let cutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("StickerExtractVC") as! StickerExtractViewController
            cutVC.imageToExtractFrom = image!
            cutVC.onExtractedSticker = {
                (image: UIImage) in
                self.changeImage(image)
            }
            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(cutVC, animated: true, completion: nil)
        }
        
        func changeImage(image: UIImage?) {
            self.image = image
            if let cb = onImageChanged {
                cb(image)
            }
        }
    }
}
