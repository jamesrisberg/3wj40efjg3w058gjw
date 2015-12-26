//
//  HorizontalItemPicker.swift
//  computer
//
//  Created by Nate Parrott on 12/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class HorizontalItemPicker: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        flow.scrollDirection = .Horizontal
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flow)
        collectionView.backgroundColor = nil
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        collectionView.registerClass(Cell.self, forCellWithReuseIdentifier: "Cell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var strings: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var selectedIndex: Int? {
        get {
            return collectionView.indexPathsForSelectedItems()?.first?.item
        }
        set(val) {
            for index in collectionView.indexPathsForSelectedItems() ?? [] {
                collectionView.deselectItemAtIndexPath(index, animated: false)
            }
            if let i = val {
                collectionView.selectItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0), animated: false, scrollPosition: .Left)
            }
        }
    }
    
    var onSelectionChange: (Int? -> ())?
    
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    // MARK: CollectionView
    
    class Cell: UICollectionViewCell {
        func setup() {
            if label == nil {
                label = UILabel(frame: bounds)
                addSubview(label!)
                label!.alpha = selected ? 1 : 0.5
                label!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                label!.textAlignment = .Center
            }
        }
        var label: UILabel?
        var text: NSAttributedString? {
            didSet {
                setup()
                label!.attributedText = text
            }
        }
        override var selected: Bool {
            get { return super.selected }
            set(val) {
                super.selected = val
                setup()
                label!.alpha = val ? 1 : 0.5
            }
        }
    }
    
    var collectionView: UICollectionView!
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return strings.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! Cell
        cell.text = createAttributedString(strings[indexPath.item])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cb = onSelectionChange {
            cb(selectedIndex)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let str = createAttributedString(strings[indexPath.item])
        let width = str.size().width + 20
        return CGSizeMake(width, bounds.size.height)
    }
    
    func createAttributedString(text: String) -> NSAttributedString {
        let font = UIFont.systemFontOfSize(12)
        let attrs: [String: AnyObject] = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.whiteColor()]
        return NSAttributedString(string: text, attributes: attrs)
    }
}
