//
//  RefreshFooter.swift
//  Matters
//
//  Created by John on 2019/1/13.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import UIKit
import PullToRefreshKit

public class RefreshFooter: UIView, RefreshableFooter {
    private let spinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    let textLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 140, height: 40))

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        addSubview(textLabel)
        textLabel.font = UIFont.systemFont(ofSize: 10)
        textLabel.textAlignment = .center
        textLabel.textColor = .lightGray
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = CGPoint(x: frame.width/2, y: frame.size.height/2)
        textLabel.center = CGPoint(x: frame.width/2, y: frame.size.height/2)
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
        textLabel.isHidden = false
    }

    public func didResetToDefault() {
        textLabel.isHidden = true
    }

    public func shouldBeginRefreshingWhenScroll() -> Bool {
        return true
    }
}
