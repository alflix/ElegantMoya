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

    public func handle(page: Pagination?, datas: [T], transform: ((T)->ViewModel<T>)? = nil) {
        if isFirstPage { dataSource = [] }
        updateRefreshStateAndChangePage(pagination: page)
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
            if !isCache {
                strongSelf.handle(page: response?.page, datas: datas, transform: transform)
            }
            completion?(response, isCache)
        }) { [weak self] (_) in
            self?.endLoadDataFail()
        }
    }
}
