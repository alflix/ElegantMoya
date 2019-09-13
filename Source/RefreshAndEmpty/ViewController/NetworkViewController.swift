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
        return nil
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
    /// 加载第一页
    @objc func loadFirstPage() {
        page = RefreshAndEmpty.PageSetting.firstPage
        loadData()
    }

    /// 加载成功调用, 会自动调用 reloadData()
    func endLoadDataSuccesslly() {
        loadingState = .success
        refreshScrollView?.reloadDataAnyway()
    }

    /// 加载失败调用
    func endLoadDataFail() {
        loadingState = .fail
        updateRefresherState(hasNextPage: false)
        refreshScrollView?.switchRefreshFooter(to: .removed)
    }

    var isFirstPage: Bool {
        return page == RefreshAndEmpty.PageSetting.firstPage
    }

    /// 更新刷新状态，并修改 page 的值
    func updateRefreshStateAndChangePage(pagination: Pagination?) {
        guard let pagination = pagination else {
            updateRefresherState(hasNextPage: false)
            return
        }
        if pagination.last > pagination.page {
            page = (page ?? RefreshAndEmpty.PageSetting.firstPage) + 1
        } else {
            page = pagination.page
        }
        updateRefresherState(hasNextPage: pagination.last > pagination.page)
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
            self?.loadFirstPage()
        }
    }

    /// 设置上拉加载
    func setupRefreshFooter() {
        refreshScrollView?.configRefreshFooter(with: RefreshFooter(), container: self) { [weak self] in
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
