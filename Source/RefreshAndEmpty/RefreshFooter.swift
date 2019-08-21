//
//  RefreshFooter.swift
//  Matters
//
//  Created by John on 2019/1/13.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import UIKit

public class RefreshFooter: UIView, RefreshableFooter {
    private let spinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = CGPoint(x: frame.width/2, y: frame.size.height/2)
    }

    public func heightForFooter() -> CGFloat {
        return 44
    }

    public func didBeginRefreshing() {
        isUserInteractionEnabled = true
        spinner.startAnimating()
    }

    public func didEndRefreshing() {
        spinner.stopAnimating()
    }

    public func didUpdateToNoMoreData() {
    }

    public func didResetToDefault() {
    }

    public func shouldBeginRefreshingWhenScroll() -> Bool {
        return true
    }
}
