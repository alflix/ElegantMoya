//
//  NetworkViewModelsViewController.swift
//  ElegantMoya
//
//  Created by John on 2019/9/10.
//

import UIKit
import GGUI

open class NetworkViewModelsViewController<T>: NetworkViewController where T: Codable {
    public var dataSource: [ViewModel<T>] = []

    public func handleData(page: Pagination?, isCache: Bool) {
        if isFirstPage { dataSource = [] }
        updateRefreshStateAndChangePage(pagination: page, isCache: isCache)
        if !isCache {
            endLoadDataSuccesslly()
        }
    }

    public func handle(page: Pagination?, isCache: Bool, datas: [T], transform: ((T)->ViewModel<T>)? = nil) {
        // 第一页，清空数据
        if isFirstPage { dataSource = [] }
        if isCache, let page = page, page.page > Pagination.PageSetting.firstPage {
            return
        }
        updateRefreshStateAndChangePage(pagination: page, isCache: isCache)
        if let transform = transform {
            dataSource.append(contentsOf: datas.map(transform))
        } else {
            dataSource.append(contentsOf: datas.map { ViewModel<T>(model: $0) })
        }
        if !isCache {
            endLoadDataSuccesslly()
        } else {
            refreshScrollView?.reloadDataAnyway()
        }
    }

    public func requestList<API: ElegantMayaProtocol>(api: API,
                                                      in view: UIView? = nil,
                                                      transform: ((T)->ViewModel<T>)? = nil,
                                                      completion: NetworkSuccessBlock<T>? = nil) {
        Network<T>().request(api, in: view, completion: { [weak self] (response, isCache) in
            guard let self = self, let datas = response.models else { return }
            self.handle(page: response.page, isCache: isCache, datas: datas, transform: transform)
            completion?(response, isCache)
        }) { [weak self] (_) in
            self?.endLoadDataFail(isShow: self?.dataSource.count == 0)
        }
    }
}
