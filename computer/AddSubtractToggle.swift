import UIKit

class AddSubtractToggle: UIView {
    override init(frame: CGRect) {
        addButton = UIButton(type: UIButtonType.Custom) as UIButton
        addButton.setTitle("+", forState: UIControlState.Normal)
        subtractButton = UIButton(type: UIButtonType.Custom) as UIButton
        subtractButton.setTitle("-", forState: UIControlState.Normal)
        for button in [addButton, subtractButton] {
            button.titleLabel!.font = UIFont(name: "AvenirNextCondensed-Heavy", size: 30)
            button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        }
        
        super.init(frame: frame)
        
        clipsToBounds = true
        
        let background = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        background.frame = self.bounds
        background.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        addSubview(background)
        
        let dividerWidth: CGFloat = 1.0
        let divider = UIView(frame: CGRectMake(self.bounds.size.width/2-dividerWidth/2, 0, dividerWidth, self.bounds.size.height))
        divider.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        divider.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.6)
        addSubview(divider)
        
        addSubview(addButton)
        addButton.frame = CGRectMake(0, 0, self.bounds.size.width/2, self.bounds.size.height)
        addButton.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addButton.addTarget(self, action: "tapped:", forControlEvents: UIControlEvents.TouchUpInside)
        addButton.setTitleColor(self.tintColor, forState: UIControlState.Selected)
        
        addSubview(subtractButton)
        subtractButton.frame = CGRectMake(self.bounds.size.width/2, 0, self.bounds.size.width/2, self.bounds.size.height)
        subtractButton.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        subtractButton.addTarget(self, action: "tapped:", forControlEvents: UIControlEvents.TouchUpInside)
        subtractButton.setTitleColor(self.tintColor, forState: UIControlState.Selected)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var adding: Bool = true {
    didSet {
        addButton.selected = adding
        subtractButton.selected = !adding
    }
    }
    var toggled: (()->())?
    
    var addButton: UIButton
    var subtractButton: UIButton
    
    func tapped(sender: UIButton) {
        adding = sender==addButton
        toggled?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.height/2
    }
}
