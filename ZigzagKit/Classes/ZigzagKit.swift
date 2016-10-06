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

@objc public protocol ZGNavigationItemDelegate : NSObjectProtocol {
    func viewController(_ viewController:UIViewController, shouldDisplayBackButton button:UIBarButtonItem) -> Bool
    
    /**
     backButtonForViewController
     
     - Parameter viewController: Le view controller qui se verra attaché le bouton
     
     - Returns: Un UIBarbuttonItem pouvant overridé celui par défaut
     */
    func backButtonForViewController(_ viewController:UIViewController) -> UIBarButtonItem?
    @objc optional func backButtonColorForViewController(_ viewController:UIViewController) -> UIColor?
    
}


public extension UIViewController {
    var hideNavigationBar: Bool {
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
    
    
    var invisibleNavigationBar: Bool? {
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
    
    static public func topMostController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        
        while let VC = topController?.presentedViewController {
            topController = VC
        }
        
        return topController
    }
    public func  showPreviousController(_ animated:Bool = true, completionBlock: ((_ previousController:UIViewController?) -> Void)? = nil) {
        if let navC = self.navigationController {
            
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
}

public protocol Storyboarded : NSObjectProtocol {
    
    associatedtype VCType = Self
    
    static func createFromStoryboard() -> VCType
    static var storyboardName : String { get }
    static var storyboardViewControllerIdentifier : String { get }
}

extension Storyboarded  {
    
    static public func createFromStoryboard() -> VCType {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: storyboardViewControllerIdentifier) as! VCType
    }
}

public protocol ReusableCell : class {
    static var reuseIdentifier : String { get }
}

extension UITableView {
    public func registerClass<Cell:AnyObject>(_ cellClass: Cell.Type?) where Cell:ReusableCell {
        self.register(cellClass.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    public func dequeueReusableCellWithClass<Cell:AnyObject>(_ cellClass: Cell.Type, forIndexPath indexPath: IndexPath) -> Cell where Cell:ReusableCell {
        
        return self.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }
    
}

public class ZGContentView : UIView {
    
    enum Edge : Int { case top, left, right, bottom }
    
    public let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    fileprivate(set) var edgesConstraints = [Edge:NSLayoutConstraint]()
    fileprivate var maskingViewController : UIViewController!
    
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
