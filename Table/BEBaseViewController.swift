//
//  BEBaseViewController.swift
//  BlogExample-AssociatedType
//
//  Created by Nguyen Tuan on 5/27/17.
//  Copyright © 2017 helo. All rights reserved.
//

import UIKit

public class BEBaseViewController<T : BECellDataSource>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var dataSource: [T] = []
    var tableView: UITableView
    
    init(tableView tb: UITableView) {
        tableView = tb
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        tableView.rowHeight = 60
        view = tableView
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        T.register(tableView: tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        //clear empty cell
        tableView.tableFooterView = UIView()
        
        tableView.reloadData()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - TableView
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: content.cellIdentifier())!
        
        if let signUpCell = cell as? BECellRender {
            signUpCell.renderCell(data: content)
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let content = dataSource[indexPath.row]
        let dynamicHeight = content.cellHeight()
        
        return dynamicHeight > 0 ? dynamicHeight : tableView.rowHeight
    }
}
