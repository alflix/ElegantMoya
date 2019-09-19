//
//  NetworkViewModelsViewController.swift
//  Alamofire
//
//  Created by John on 2019/9/10.
//

import UIKit
import GGUI

open class NetworkViewModelsViewController<T>: NetworkViewController where T: Codable {
    public var dataSource: [ViewModel<T>] = []

    public func handleData(page: Pagination?) {
        if isFirstPage { dataSource = [] }
        updateRefreshStateAndChangePage(pagination: page)
        endLoadDataSuccesslly()
    }

    public func handle(page: Pagination, isCache: Bool, datas: [T], transform: ((T)->ViewModel<T>)? = nil) {
        // 第一页，清空数据
        if isFirstPage { dataSource = [] }
        if !isCache {
            updateRefreshStateAndChangePage(pagination: page)
        }
        if page.page > Pagination.PageSetting.firstPage && isCache {
            // 大于第一页的缓存数据不处理
            return
        }
        if let transform = transform {
            dataSource.append(contentsOf: datas.map(transform))
        } else {
            dataSource.append(contentsOf: datas.map { ViewModel<T>(model: $0) })
        }
        endLoadDataSuccesslly()
    }

    public func requestList<API: ElegantMayaProtocol>(api: API,
                                                      transform: ((T)->ViewModel<T>)? = nil,
                                                      completion: NetworkListSuccessBlock<T>? = nil) {
        Network<T>().requestList(api, completion: { [weak self] (response, isCache) in
            guard let strongSelf = self, let datas = response?.datas else { return }
            strongSelf.handle(page: response?.page ?? Pagination(page: Pagination.PageSetting.firstPage, size: Pagination.PageSetting.pageSize, last: 0, total: 0),
                              isCache: isCache,
                              datas: datas,
                              transform: transform)
            completion?(response, isCache)
        }) { [weak self] (_) in
            self?.endLoadDataFail()
        }
    }
}
