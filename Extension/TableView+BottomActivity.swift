//
//  TableView+BottomActivity.swift
//  Utility
//
//  Created by Nguyen Tuan on 9/6/17.
//  Copyright © 2017 Nguyen Tuan. All rights reserved.
//

import UIKit

import UIKit

class TableBotomActivityView: UIView {
    fileprivate var activityView: UIActivityIndicatorView!
    
    fileprivate var isLoading: Bool = false
    var action: (()->())?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityView)
        
        activityView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    func startLoad() {
        guard !isLoading else {
            return
        }
        
        isLoading = true
        activityView.startAnimating()
        action?()
    }
    
    func endLoad() {
        isLoading = false
        activityView.stopAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIScrollView {
    
    private func bottomActivityView() -> TableBotomActivityView? {
        return viewWithTag(10001) as? TableBotomActivityView
    }
    
    @discardableResult
    public func addBotomActivityView(loadMore: (()->())? = nil) -> Bool {
        if let _ = bottomActivityView() {
            //should return
            return false
        }
        
        let bottomView = TableBotomActivityView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 60))
        bottomView.tag = 10001
        bottomView.action = loadMore
        
        if let tableview = self as? UITableView {
            tableview.tableFooterView = bottomView
        }else {
            self.insertSubview(bottomView, at: 0)
            bottomView.isHidden = true
        }
        
        self.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        
        return true
    }
    
    public func removeBottomActivityView() {
        if let v = bottomActivityView() {
            v.removeFromSuperview()
            self.removeObserver(self, forKeyPath: "contentOffset")
            if let tableview = self as? UITableView {
                tableview.tableFooterView = UIView()
            }
        }
    }
    
    public func endBottomActivity() {
        if let v = bottomActivityView() {
            v.endLoad()
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if "contentOffset" == keyPath {
            let offsetY = contentOffset.y
            let h = bounds.size.height
            let totalHeight = contentSize.height
            
            if totalHeight - offsetY < (h + 60) {
                if let activityView = bottomActivityView() {
                    activityView.startLoad()
                }
            }
        }
    }
}

