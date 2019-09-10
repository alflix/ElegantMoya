//
//  NetworkViewController.swift
//  Ganguo
//
//  Created by John on 2019/7/10.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import GGUI

/// 加载状态
///
/// - before: 不显示占位图
/// - loading: 不显示占位图（可以配置显示 loading）
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

open class NetworkViewController: UIViewController {
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
            fatalError("must override this variable or DefaultSetting.emptyImage must not be nil")
        }
        return emptyImage
    }

    /// 显示占位的父视图 must override
    open var refreshScrollView: UIScrollView? {
        #if DEBUG
        assert(false, "must override refreshScrollView ")
        #endif
        return UIScrollView()
    }

    /// 第几页
    public var page: Int? = RefreshAndEmpty.PageSetting.firstPage
    /// 加载状态
    public var loadingState: LoadingState = .before

    /// must override
    open func loadData() {
        #if DEBUG
        assert(false, "must override loadData ")
        #endif
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupRefresh()
    }
}

public extension NetworkViewController {
    func endLoadData() {
        loadingState = .success
        refreshScrollView?.reloadDataAnyway()
    }

    var isFirstPage: Bool {
        return page == RefreshAndEmpty.PageSetting.firstPage
    }
}

public extension NetworkViewController {
    /// 设置下拉刷新和上拉加载
    func setupRefresh() {
        setupRefreshHeader()
        setupRefreshFooter()
    }

    /// 设置下拉刷新
    func setupRefreshHeader() {
        refreshScrollView?.configRefreshHeader(with: Refresher(), container: self) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadFirstPage()
        }
    }

    /// 设置上拉加载
    func setupRefreshFooter() {
        refreshScrollView?.configRefreshFooter(with: RefreshFooter(), container: self) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadData()
        }
    }

    @objc func loadFirstPage() {
        page = RefreshAndEmpty.PageSetting.firstPage
        loadData()
    }

    /// 更新刷新状态，并修改 page 的值
    func updateRefreshStateAndChangePage(pagination: Pagination?) {
        guard let pagination = pagination else { return }
        if pagination.last > pagination.page {
            page = (page ?? RefreshAndEmpty.PageSetting.firstPage) + 1
        } else {
            page = pagination.page
        }
        updateRefreshState(pagination: pagination)
    }

    /// 更新刷新状态
    func updateRefreshState(pagination: Pagination) {
        updateRefresherState(hasNextPage: pagination.last > pagination.page)
    }

    /// 开始下拉刷新
    func beginHeaderRefresher() {
        refreshScrollView?.switchRefreshHeader(to: .refreshing)
    }

    /// 结束刷新
    func endRefresher() {
        updateRefresherState(hasNextPage: false)
        refreshScrollView?.switchRefreshFooter(to: .removed)
    }

    /// 更新下拉刷新器和上拉加载器状态
    ///
    /// - Parameter hasNextPage: 是否有下一页
    private func updateRefresherState(hasNextPage: Bool) {
        refreshScrollView?.switchRefreshFooter(to: hasNextPage ? .normal : .noMoreData)
        refreshScrollView?.switchRefreshHeader(to: .normal(.none, 0.0))
    }
}

extension NetworkViewController: DZNEmptyDataSetSource & DZNEmptyDataSetDelegate {
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: emptyTitle, attributes: RefreshAndEmpty.DefaultSetting.titleAttributes())
    }

    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return emptyImage
    }

    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return view.height/RefreshAndEmpty.DefaultSetting.verticalOffsetProportion
    }

    public func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }

    public func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return loadingState != .before
    }
}
