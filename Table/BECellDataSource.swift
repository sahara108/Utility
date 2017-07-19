//
//  BETableViewCellDataSource.swift
//  BlogExample-AssociatedType
//
//  Created by Nguyen Tuan on 5/27/17.
//  Copyright © 2017 helo. All rights reserved.
//
import UIKit

public protocol BECellDataSource {
    func cellIdentifier() -> String
    func cellHeight() -> CGFloat
    static func register(tableView: UITableView)
}
