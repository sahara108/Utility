//
//  BECell.swift
//  BlogExample-AssociatedType
//
//  Created by Nguyen Tuan on 5/27/17.
//  Copyright © 2017 helo. All rights reserved.
//

import UIKit

public protocol BECellRender {
    func renderCell(data: BECellDataSource)
}

public protocol BECellRenderImpl: BECellRender {
    associatedtype CellData
    func renderCell(data: CellData)
}

public extension BECellRender where Self: BECellRenderImpl {
    func renderCell(data: BECellDataSource) {
        if let d = data as? CellData {
            renderCell(data: d)
        }
    }
}
