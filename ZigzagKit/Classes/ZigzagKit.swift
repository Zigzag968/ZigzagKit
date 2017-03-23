//
//  ZigzagHelpers.swift
//  Evaneos
//
//  Created by Alexandre Guibert on 26/09/2016.
//  Copyright © 2016 Evaneos. All rights reserved.
//

import UIKit
import PropertyExtensions

private var hideNavigationBarKey: UInt8 = 0
private var invisibleNavigationBarKey: UInt8 = 0

private var navigationItemDelegateKey: UInt8 = 0

@objc
public protocol ZGNavigationItemDelegate : NSObjectProtocol {
    func viewController(viewController:UIViewController, shouldDisplayBackButton button:UIBarButtonItem) -> Bool
    
    /**
     viewControllerShouldDismiss
     
     This method is a delegate for showPreviousController() that needs to be called before
     
     - Parameter viewController: The viewController to dismiss
     
     */
    func viewControllerShouldDismiss(viewController:UIViewController, block:(Bool)->())
    
    /**
     backButtonForViewController
     
     - Parameter viewController: Le view controller qui se verra attaché le bouton
     
     - Returns: Un UIBarbuttonItem pouvant overridé celui par défaut
     */
    func backButtonForViewController(viewController:UIViewController) -> UIBarButtonItem?
    optional func backButtonColorForViewController(viewController:UIViewController) -> UIColor?
    
}


extension UIViewController {
    public var hideNavigationBar: Bool {
        get {
            let str = objc_getAssociatedObject(self, &hideNavigationBarKey) as? NSString
            if (str == "1") {
                return true
            }
            return false
        }
        set(newValue) {
            var str = "0"
            if (newValue == true) {
                str = "1"
            }
            objc_setAssociatedObject(self, &hideNavigationBarKey, str, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    
    public var invisibleNavigationBar: Bool? {
        get {
            let str = objc_getAssociatedObject(self, &invisibleNavigationBarKey) as? NSString
            if (str == "1") {
                return true
            }
            return false
        }
        set(newValue) {
            var str = "0"
            if (newValue == true) {
                str = "1"
            }
            objc_setAssociatedObject(self, &invisibleNavigationBarKey, str, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    
    public var navigationItemDelegate: ZGNavigationItemDelegate? {
        get {
            return objc_getAssociatedObject(self, &navigationItemDelegateKey) as? ZGNavigationItemDelegate
        }
        set(newValue) {
            objc_setAssociatedObject(self, &navigationItemDelegateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public static func topMostController() -> UIViewController? {
        var topController = UIApplication.sharedApplication().keyWindow?.rootViewController
        
        while let VC = topController?.presentedViewController {
            topController = VC
        }
        
        return topController
    }
    
    public func showPreviousController(animated:Bool = true, completionBlock: ((previousController:UIViewController?) -> Void)? = nil) {
        
        func dismiss() {
            if let navC = self.navigationController {
                CATransaction.begin()
                CATransaction.setCompletionBlock({ () -> Void in
                    let vc = navC.viewControllers.last
                    completionBlock?(previousController: vc)
                })
                navC.popViewControllerAnimated(animated)
                CATransaction.commit()
            }
            else if let presentingViewController = self.presentingViewController {
                presentingViewController.dismissViewControllerAnimated(animated, completion: { () -> Void in
                    completionBlock?(previousController: presentingViewController)
                })
            }
        }
        
        if let delegate = self.navigationItemDelegate {
            delegate.viewControllerShouldDismiss(self, block: { (should) in
                if should { dismiss() }
            })
        } else {
            dismiss()
        }
        
    }
}

public protocol Storyboarded : NSObjectProtocol {
    
    associatedtype VCType = Self
    
    static func createFromStoryboard() -> VCType
    static var storyboardName : String { get }
    static var storyboardViewControllerIdentifier : String { get }
}

extension Storyboarded  {
    
    public static func createFromStoryboard() -> VCType {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewControllerWithIdentifier(storyboardViewControllerIdentifier) as! VCType
    }
}

public protocol ReusableCell : class {
    static var reuseIdentifier : String { get }
    static var cellNibName : String? { get }
}

extension UIScrollView : PropertyExtensions {
    var _beforeAdjustTopInset : CGFloat? {
        get { return self.getProperty("_beforeAdjustTopInset") }
        set { self.setValue(newValue, forProperty: "_beforeAdjustTopInset") }
    }
    
    var _beforeAdjustBottomInset : CGFloat? {
        get { return self.getProperty("_beforeAdjustBottomInset") }
        set { self.setValue(newValue, forProperty: "_beforeAdjustBottomInset") }
    }
    
    public enum Edge {
        case Top, Bottom
    }
    
    private func adjustInsetEdgeWithLayoutGuide(layoutGuide:UILayoutSupport, edge:Edge) {
        
        let inset = layoutGuide.length
        setInsetForEdge(inset, edge: edge)
    }
    
    private func setInsetForEdge(inset:CGFloat, edge:Edge) {
        
        var insets = self.contentInset
        
        switch edge {
        case .Top:
            _beforeAdjustTopInset = _beforeAdjustTopInset ?? insets.top
            insets.top = inset + _beforeAdjustTopInset!
            break
        case .Bottom:
            _beforeAdjustBottomInset = _beforeAdjustBottomInset ?? insets.bottom
            insets.bottom = inset + _beforeAdjustBottomInset!
            break
        }
        
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
    
    public func adjustBottomInsetsWithBottomLayoutGuide(layoutGuide:UILayoutSupport) {
        self.adjustInsetEdgeWithLayoutGuide(layoutGuide, edge: .Bottom)
    }
    
    public func adjustTopInsetsWithTopLayoutGuide(layoutGuide:UILayoutSupport) {
        self.adjustInsetEdgeWithLayoutGuide(layoutGuide, edge: .Top)
    }
    
    public func setTopInset(inset:CGFloat) {
        self.setInsetForEdge(inset, edge: .Top)
    }
    
    public func setBottomInset(inset:CGFloat) {
        self.setInsetForEdge(inset, edge: .Bottom)
    }
    
    public func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
        if bottomOffset.y > 0 {
            self.setContentOffset(bottomOffset, animated: true)
        }
    }
}

extension UITableView {
    
    public func registerNibForClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type?, nibName:String?=nil) {
        self.registerNib(UINib(nibName: nibName ?? Cell.cellNibName ?? String(cellClass!), bundle: nil), forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func registerClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type?) {
        self.registerClass(cellClass.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func dequeueReusableCellWithClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type, forIndexPath indexPath: NSIndexPath) -> Cell {
        
        return self.dequeueReusableCellWithIdentifier(Cell.reuseIdentifier, forIndexPath: indexPath) as! Cell
    }
}

extension UICollectionView {
    
    public func registerNibForClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type?, nibName:String?=nil) {
        self.registerNib(UINib(nibName: nibName ?? Cell.cellNibName ?? String(cellClass!), bundle: nil), forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func registerClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type?) {
        self.registerClass(cellClass.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func dequeueReusableCellWithClass<Cell:AnyObject where Cell:ReusableCell>(cellClass: Cell.Type, forIndexPath indexPath: NSIndexPath) -> Cell {
        
        return self.dequeueReusableCellWithReuseIdentifier(Cell.reuseIdentifier, forIndexPath: indexPath) as! Cell
    }
}

public class ZGContentView : UIView {
    
    enum Edge : Int { case top, left, right, bottom }
    
    public let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    private(set) var edgesConstraints = [Edge:NSLayoutConstraint]()
    private var maskingViewController : UIViewController!
    
    required public init(viewController:UIViewController) {
        super.init(frame: CGRectZero)
        self.maskingViewController = viewController
        setup()
    }
    
    func setup() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        super.addSubview(self.contentView)
        
        edgesConstraints[Edge.top] = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 0)
        edgesConstraints[Edge.top]?.priority = UILayoutPriorityDefaultHigh
        
        edgesConstraints[Edge.bottom] = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: 0)
        edgesConstraints[Edge.bottom]?.priority = UILayoutPriorityDefaultHigh
        
        edgesConstraints[Edge.right] = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: contentView, attribute: .Right, multiplier: 1, constant: 0)
        edgesConstraints[Edge.left] = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 0)
        
        edgesConstraints.forEach { (item) in
            self.addConstraint(item.1)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func addSubview(view: UIView) {
        self.contentView.addSubview(view)
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        let topGuideConstraint = NSLayoutConstraint(item: self.contentView, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: maskingViewController.topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
        topGuideConstraint.priority = UILayoutPriorityRequired
        maskingViewController.view.addConstraint(topGuideConstraint)
        
        let bottomGuideConstraint = NSLayoutConstraint(item:maskingViewController.bottomLayoutGuide, attribute: .Bottom, relatedBy: .GreaterThanOrEqual, toItem: self.contentView, attribute: .Top, multiplier: 1, constant: 0)
        bottomGuideConstraint.priority = UILayoutPriorityRequired
        maskingViewController.view.addConstraint(bottomGuideConstraint)
    }
    
}

extension UIView {
    public func addBorder(edges edges: UIRectEdge, colour: UIColor = UIColor.whiteColor(), thickness: CGFloat = 1) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRectZero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.Top) || edges.contains(.All) {
            let top = border()
            addSubview(top)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.Left) || edges.contains(.All) {
            let left = border()
            addSubview(left)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.Right) || edges.contains(.All) {
            let right = border()
            addSubview(right)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.Bottom) || edges.contains(.All) {
            let bottom = border()
            addSubview(bottom)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[bottom]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        return borders
    }
}
