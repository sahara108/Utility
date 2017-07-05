//
//  UIImageView+Url.swift
//  Utility
//
//  Created by Nguyen Tuan on 7/5/17.
//  Copyright © 2017 Nguyen Tuan. All rights reserved.
//

import UIKit

extension UIImageView {
    public func loadImage(fromURL: URL?, defaultImage: UIImage? = nil) {
        FileProviderService.service.imageView(self, loadImage: fromURL, defaultImage: defaultImage)
    }
}
