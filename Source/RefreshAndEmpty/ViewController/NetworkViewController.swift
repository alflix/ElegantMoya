//
//  NetworkViewController.swift
//  ElegantMoya
//
//  Created by John on 2019/7/10.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

/// 加载状态
///
/// - before: 不显示占位图
/// - loading: 不显示占位图（这个状态暂时和 before 一样）
/// - success: 可显示占位图
/// - fail: 可显示网络错误视图
public enum LoadingState {
    /// 未加载
    case before
    /// 加载中
    case loading
    /// 加载成功
    case success
    /// 加载失败
    case fail
}

public enum RefreshType {
    case header
    case footer
    case headerAndFooter
}

open class NetworkViewController: UIViewController {
    /// 加载数据失败后显示的视图
    private var loadFailedView: UIView?

    /// 占位文字 optional override
    open var emptyTitle: String {
        guard let emptyTitle = RefreshAndEmpty.DefaultSetting.emptyTitle else {
            fatalError("must override this variable or DefaultSetting.emptyTitle must not be nil")
        }
        return emptyTitle
    }

    /// 占位图片 optional override
    open var emptyImage: UIImage {
        guard let emptyImage = RefreshAndEmpty.DefaultSetting.emptyImage else {
            if #available(iOS 11.0, *) {
                return UIImage()
            }
            /// fix ios 10 UIImage() 闪退
            return UIImage().resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: CGFloat.leastNonzeroMagnitude, bottom: 0, right: 0))
        }
        return emptyImage
    }

    /// 设置刷新类型，默认头部和底部
    open var refreshType: RefreshType {
        return .headerAndFooter
    }

    /// 头部头部控件需要调整的距离
    open var adjustOffsetForHeader: CGFloat {
        return 0
    }

    /// 刷新到最后一页时显示的文字
    open var noMoreDataText: String? {
        return nil
    }

    /// 显示占位的父视图 must override
    open var refreshScrollView: UIScrollView? {
        assert(false, "must override refreshScrollView ")
        return nil
    }

    /// 第几页
    public var page: Int = Pagination.PageSetting.firstPage
    /// 加载状态
    public var loadingState: LoadingState = .before

    /// 是否是最后一页
    public var isLastPage: Bool = true

    /// must override
    open func loadData() {
        assert(false, "must override loadData ")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupRefresh()
    }
}

public extension NetworkViewController {
    /// 加载第一页
    @objc func loadFirstPage() {
        page = Pagination.PageSetting.firstPage
        loadData()
    }

    /// 加载成功调用, 会自动调用 reloadData()
    func endLoadDataSuccesslly() {
        loadingState = .success
        refreshScrollView?.switchRefreshHeader(to: .normal(.none, 0.0))
        refreshScrollView?.reloadDataAnyway()
    }

    /// 加载失败调用(是否显示加载数据失败后的视图，默认显示)
    func endLoadDataFail(isShow: Bool = true, contentInset: UIEdgeInsets = .zero) {
        loadingState = .fail
        updateRefresherState(hasNextPage: false)
        refreshScrollView?.switchRefreshFooter(to: .removed)
        setupLoadFailedView(isShow: isShow, contentInset: contentInset)
    }

    var isFirstPage: Bool {
        return page == Pagination.PageSetting.firstPage
    }

    /// 更新刷新状态，并修改 page 的值
    func updateRefreshStateAndChangePage(pagination: Pagination?, isCache: Bool) {
        guard let pagination = pagination else {
            if !isCache {
                updateRefresherState(hasNextPage: false)
            }
            return
        }
        if pagination.last > pagination.page {
            page = (page ?? Pagination.PageSetting.firstPage) + 1
        } else {
            page = pagination.page
        }
        if !isCache {
            updateRefresherState(hasNextPage: pagination.last > pagination.page)
        }
    }
}

public extension NetworkViewController {
    /// 设置下拉刷新和上拉加载
    func setupRefresh() {
        switch refreshType {
        case .header:
            setupRefreshHeader(adjustOffset: adjustOffsetForHeader)
        case .footer:
            setupRefreshFooter()
        case .headerAndFooter:
            setupRefreshHeader(adjustOffset: adjustOffsetForHeader)
            setupRefreshFooter()
        }
    }

    /// 设置下拉刷新
    func setupRefreshHeader(adjustOffset: CGFloat = 0) {
        let refresher = Refresher()
        refresher.adjustOffset = adjustOffset
        refreshScrollView?.configRefreshHeader(with: refresher, container: self) { [weak self] in
            self?.loadFirstPage()
        }
    }

    /// 设置上拉加载
    func setupRefreshFooter() {
        let footer = RefreshFooter()
        footer.textLabel.text = noMoreDataText
        refreshScrollView?.configRefreshFooter(with: footer, container: self) { [weak self] in
            self?.loadData()
        }
    }

    /// 开始下拉刷新
    func beginHeaderRefresher() {
        refreshScrollView?.switchRefreshHeader(to: .refreshing)
    }
}

extension NetworkViewController {
    /// 更新下拉刷新器和上拉加载器状态
    ///
    /// - Parameter hasNextPage: 是否有下一页
    public func updateRefresherState(hasNextPage: Bool) {
        isLastPage = !hasNextPage
        refreshScrollView?.switchRefreshFooter(to: hasNextPage ? .normal : .noMoreData)
        refreshScrollView?.switchRefreshHeader(to: .normal(.none, 0.0))
    }

    /// 是否显示加载数据失败后的视图
    private func setupLoadFailedView(isShow: Bool, contentInset: UIEdgeInsets) {
        if !isShow || loadFailedView != nil {
            loadFailedView?.alpha = 1
            return
        }
        guard let loadFailedView = RefreshAndEmpty.DefaultSetting.loadFailedClosure({ [weak self] in
            self?.loadFailedView?.alpha = 1
            UIView.animate(withDuration: 0.3, animations: {
                self?.loadFailedView?.alpha = 0
            }, completion: { (_) in
                self?.loadData()
            })
        }) else { return }
        self.loadFailedView = loadFailedView
        view.addSubview(loadFailedView)
        view.bringSubviewToFront(loadFailedView)
        if !(view is UITableView) {
            loadFailedView.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addConstraint(NSLayoutConstraint(item: loadFailedView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: contentInset.top))

        view.addConstraint(NSLayoutConstraint(item: loadFailedView,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .left,
                                              multiplier: 1,
                                              constant: contentInset.left))

        view.addConstraint(NSLayoutConstraint(item: loadFailedView,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .right,
                                              multiplier: 1,
                                              constant: contentInset.right))

        view.addConstraint(NSLayoutConstraint(item: loadFailedView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: contentInset.bottom))
    }
}

extension NetworkViewController: DZNEmptyDataSetSource & DZNEmptyDataSetDelegate {
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: emptyTitle, attributes: RefreshAndEmpty.DefaultSetting.titleAttributes)
    }

    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return emptyImage
    }

    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        if let verticalOffsetProportion = RefreshAndEmpty.DefaultSetting.verticalOffsetProportion {
            return view.bounds.height/verticalOffsetProportion
        }
        return 0
    }

    public func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }

    public func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return loadingState != .before
    }
}
