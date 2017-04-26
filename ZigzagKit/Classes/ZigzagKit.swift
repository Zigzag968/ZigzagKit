//
//  ZigzagHelpers.swift
//  Evaneos
//
//  Created by Alexandre Guibert on 26/09/2016.
//  Copyright © 2016 Evaneos. All rights reserved.
//

import UIKit

private var hideNavigationBarKey: UInt8 = 0
private var invisibleNavigationBarKey: UInt8 = 0
private var navigationItemDelegateKey: UInt8 = 0

@objc
public protocol ZGNavigationItemDelegate : NSObjectProtocol {
    @objc optional func viewController(viewController:UIViewController, shouldDisplayBackButton button:UIBarButtonItem) -> Bool
    
    /**
     viewControllerShouldDismiss
     
     This method is a delegate for showPreviousController() that needs to be called before
     
     - Parameter viewController: The viewController to dismiss
     
     */
    @objc optional func viewControllerShouldDismiss(viewController:UIViewController, block:(Bool)->())
    
    /**
     backButtonForViewController
     
     - Parameter viewController: Le view controller qui se verra attaché le bouton
     
     - Returns: Un UIBarbuttonItem pouvant overridé celui par défaut
     */
    @objc optional func backButtonForViewController(viewController:UIViewController) -> UIBarButtonItem?
    @objc optional func backButtonColorForViewController(viewController:UIViewController) -> UIColor?
    
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
        var topController = UIApplication.shared.keyWindow?.rootViewController
        
        while let VC = topController?.presentedViewController {
            topController = VC
        }
        
        return topController
    }
    
    public func showPreviousController(animated:Bool = true, completionBlock: ((_ previousController:UIViewController?) -> Void)? = nil) {
        
        // let topMostViewController = self.navigationController?.viewControllers.last ?? self.presentedViewController
        
        func dismiss() {
            if let navC = self.navigationController, navC.viewControllers.count > 1 && navC.topViewController == self {
                CATransaction.begin()
                CATransaction.setCompletionBlock({ () -> Void in
                    let vc = navC.viewControllers.last
                    completionBlock?(vc)
                })
                navC.popViewController(animated: animated)
                CATransaction.commit()
            }
            else if let presentingViewController = self.presentingViewController {
                presentingViewController.dismiss(animated: animated, completion: { () -> Void in
                    completionBlock?(presentingViewController)
                })
            }
        }
        
        if let shouldDismiss = self.navigationItemDelegate?.viewControllerShouldDismiss {
            shouldDismiss(self, { (should) in
                if should { dismiss() }
            })
        } else {
            if viewShouldDismiss() { dismiss() }
        }
        
    }
    
    public func viewShouldDismiss() -> Bool {
        return true
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
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: storyboardViewControllerIdentifier) as! VCType
    }
}

public protocol ReusableCell : class {
    static var reuseIdentifier : String { get }
    static var cellNibName : String? { get }
}

private var _beforeAdjustTopInsetKey: UInt8 = 0
private var _beforeAdjustBottomInsetKey: UInt8 = 0

extension UIScrollView {
    var _beforeAdjustTopInset : CGFloat? {
        get {
            return objc_getAssociatedObject(self, &_beforeAdjustTopInsetKey) as? CGFloat
        }
        set(newValue) {
            objc_setAssociatedObject(self, &_beforeAdjustTopInsetKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var _beforeAdjustBottomInset : CGFloat? {
        get {
            return objc_getAssociatedObject(self, &_beforeAdjustBottomInset) as? CGFloat
        }
        set(newValue) {
            objc_setAssociatedObject(self, &_beforeAdjustBottomInset, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public enum Edge {
        case Top, Bottom
    }
    
    private func adjustInsetEdgeWithLayoutGuide(layoutGuide:UILayoutSupport, edge:Edge) {
        
        let inset = layoutGuide.length
        setInsetForEdge(inset: inset, edge: edge)
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
        self.adjustInsetEdgeWithLayoutGuide(layoutGuide: layoutGuide, edge: .Bottom)
    }
    
    public func adjustTopInsetsWithTopLayoutGuide(layoutGuide:UILayoutSupport) {
        self.adjustInsetEdgeWithLayoutGuide(layoutGuide: layoutGuide, edge: .Top)
    }
    
    public func setTopInset(inset:CGFloat) {
        self.setInsetForEdge(inset: inset, edge: .Top)
    }
    
    public func setBottomInset(inset:CGFloat) {
        self.setInsetForEdge(inset: inset, edge: .Bottom)
    }
    
    public func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
        if bottomOffset.y > 0 {
            self.setContentOffset(bottomOffset, animated: true)
        }
    }
}

extension UITableView {
    
    public func registerNibForClass<Cell:AnyObject>(cellClass: Cell.Type?, nibName:String?=nil) where Cell:ReusableCell {
        self.register(UINib(nibName: nibName ?? Cell.cellNibName ?? String(describing: cellClass!), bundle: nil), forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func registerClass<Cell:AnyObject>(cellClass: Cell.Type?) where Cell:ReusableCell {
        self.register(cellClass.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func dequeueReusableCellWithClass<Cell:AnyObject>(cellClass: Cell.Type, for indexPath: IndexPath) -> Cell where Cell:ReusableCell {

        return self.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }
}

extension UICollectionView {
    
    public func registerNibForClass<Cell:AnyObject>(cellClass: Cell.Type?, nibName:String?=nil) where Cell:ReusableCell {
        self.register(UINib(nibName: nibName ?? Cell.cellNibName ?? String(describing: cellClass!), bundle: nil), forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func registerClass<Cell:AnyObject>(cellClass: Cell.Type?) where Cell:ReusableCell {
        self.register(cellClass.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func dequeueReusableCell<Cell:AnyObject>(cellClass: Cell.Type, for indexPath: IndexPath) -> Cell where Cell:ReusableCell
    {
        return self.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }
}

public class ZGContentView : UIView {
    
    enum Edge : Int { case top, left, right, bottom }
    
    public let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    private(set) var edgesConstraints = [Edge:NSLayoutConstraint]()
    private var maskingViewController : UIViewController!
    
    required public init(viewController:UIViewController) {
        super.init(frame: CGRect.zero)
        self.maskingViewController = viewController
        setup()
    }
    
    func setup() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        super.addSubview(self.contentView)
        
        edgesConstraints[Edge.top] = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0)
        edgesConstraints[Edge.top]?.priority = UILayoutPriorityDefaultHigh
        
        edgesConstraints[Edge.bottom] = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0)
        edgesConstraints[Edge.bottom]?.priority = UILayoutPriorityDefaultHigh
        
        edgesConstraints[Edge.right] = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1, constant: 0)
        edgesConstraints[Edge.left] = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 0)
        
        edgesConstraints.forEach { (item) in
            self.addConstraint(item.1)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func addSubview(_ view: UIView) {
        self.contentView.addSubview(view)
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        let topGuideConstraint = NSLayoutConstraint(item: self.contentView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: maskingViewController.topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        topGuideConstraint.priority = UILayoutPriorityRequired
        maskingViewController.view.addConstraint(topGuideConstraint)
        
        let bottomGuideConstraint = NSLayoutConstraint(item:maskingViewController.bottomLayoutGuide, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
        bottomGuideConstraint.priority = UILayoutPriorityRequired
        maskingViewController.view.addConstraint(bottomGuideConstraint)
    }
    
}

extension UIView {
    public func addBorder(edges: UIRectEdge, colour: UIColor = UIColor.white, thickness: CGFloat = 1) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRect.zero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.top) || edges.contains(.all) {
            let top = border()
            addSubview(top)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.left) || edges.contains(.all) {
            let left = border()
            addSubview(left)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.right) || edges.contains(.all) {
            let right = border()
            addSubview(right)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.bottom) || edges.contains(.all) {
            let bottom = border()
            addSubview(bottom)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[bottom]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        return borders
    }
}
