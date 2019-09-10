//
//  Network.swift
//  ElegantMoya
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
import Moya
import Cache
import GGUI

/// T: Response -> Model 的泛型
public class Network<T> where T: Codable {
    public init() { }

    /// 请求普通接口
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - completion: 结束返回数据闭包(缓存策略会影响闭包的调用时机和顺序)
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func request<API: ElegantMayaProtocol>(
        _ api: API,
        completion: NetworkSuccessBlock<T>? = nil,
        error: NetworkErrorBlock? = nil)
        -> Cancellable? {
            return request(api, modelComletion: completion, error: error)
    }

    /// 请求列表接口
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - completion: 结束返回数据闭包(缓存策略会影响闭包的调用时机和顺序)
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func requestList<API: ElegantMayaProtocol>(
        _ api: API,
        completion: NetworkListSuccessBlock<T>? = nil,
        error: NetworkErrorBlock? = nil)
        -> Cancellable? {
            return request(api, modelListComletion: completion, error: error)
    }

    // 用来处理只请求一次的栅栏队列
    private let barrierQueue = DispatchQueue(label: "hk.ganguo.Network", attributes: .concurrent)
    // 用来处理只请求一次的数组,保存请求的信息 唯一
    private var fetchRequestKeys = [String]()
}

private extension Network {
    /// 请求基类方法
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - modelComletion: 普通接口返回数据闭包
    ///   - modelListComletion: 列表接口返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    func request<API: ElegantMayaProtocol>(
        _ api: API,
        modelComletion: NetworkSuccessBlock<T>? = nil,
        modelListComletion: NetworkListSuccessBlock<T>? = nil,
        error: NetworkErrorBlock? = nil)
        -> Cancellable? {
            // 同一请求正在请求直接返回
            if isSameRequest(api) { return nil }
            let successblock = { (shouldRevoke: Bool, response: Response) in
                DispatchQueue.main.async {
                    if let temp = modelComletion {
                        self.handleSuccessResponse(api, response: response, modelComletion: shouldRevoke ? temp : nil, error: error)
                    }
                    if let temp = modelListComletion {
                        self.handleSuccessResponse(api, response: response, modelListComletion: shouldRevoke ? temp : nil, error: error)
                    }
                }
            }
            let errorblock = { (networkError: NetworkError) in
                DispatchQueue.main.async {
                    ShowHudHelper.showFail(api: api, message: networkError.message)
                    error?(networkError)
                }
            }
            let checkIfCache: () -> Bool = {
                let cacheKey = ResponseCache.uniqueKey(api)
                if let responseStorage = ResponseCache.shared.responseStorage,
                    let response = try? responseStorage.object(forKey: cacheKey) {
                    successblock(true, response)
                    return true
                }
                return false
            }
            let provider = ElegantMoya.createProvider(api: api)
            var hasCache = false

            let cachePolicy = api.cachePolicy ?? .fetchIgnoringCacheData
            switch cachePolicy {
            case .returnCacheDataAndFetch:
                hasCache = checkIfCache()
            case .returnCacheDataAndFetchBackground:
                hasCache = checkIfCache()
            case .returnCacheDataElseFetch:
                if checkIfCache() { return nil }
            case .fetchIgnoringCacheData:
                break
            case .returnCacheDataDontFetch:
                hasCache = checkIfCache()
                return nil
            }
            let cancellable = provider.request(api, callbackQueue: .global()) { (response) in
                // 请求完成移除
                self.cleanRequest(api)
                switch response {
                case .success(let response):
                    let shouldRevoke = (cachePolicy == .returnCacheDataAndFetchBackground && hasCache) ? false : true
                    successblock(shouldRevoke, response)
                case .failure:
                    errorblock(NetworkError.exception(message: ElegantMoya.ErrorMessage.server))
                }
            }
            return cancellable
    }

    /// 处理成功的返回(业务上不一定是成功)
    func handleSuccessResponse<API: ElegantMayaProtocol>(
        _ api: API,
        response: Response,
        modelComletion: NetworkSuccessBlock<T>? = nil,
        modelListComletion: NetworkListSuccessBlock<T>? = nil,
        error: NetworkErrorBlock? = nil) {
        do {
            if let temp = modelComletion {
                let modelResponse = try handleResponseData(isList: false, api: api, data: response)
                DispatchQueue.main.async {
                    ResponseCache.cacheData(api, data: response)
                    temp(modelResponse.0)
                    ShowHudHelper.showSuccess(api: api)
                }
            }
            if let temp = modelListComletion {
                let listResponse = try handleResponseData(isList: true, api: api, data: response)
                DispatchQueue.main.async {
                    ResponseCache.cacheData(api, data: response)
                    temp(listResponse.1)
                    ShowHudHelper.showSuccess(api: api)
                }
            }
        } catch let NetworkError.serverResponse(message, code) {
            ShowHudHelper.showFail(api: api, message: message)
            error?(NetworkError.serverResponse(message: message, code: code))
        } catch let NetworkError.loginStateIsexpired(message) {
            ElegantMoya.logoutClosure()
            ShowHudHelper.showFail(api: api, message: message)
            error?(NetworkError.loginStateIsexpired(message: message))
        } catch {
            #if Debug
            fatalError("unknown error")
            #endif
        }
    }

    /// 处理数据
    func handleResponseData<API: ElegantMayaProtocol>(isList: Bool, api: API, data: Response)
        throws -> (ModelResponse<T>?, ListResponse<T>?) {
            guard let json = try? JSONSerialization.jsonObject(with: data.data, options: []) else {
                throw NetworkError.jsonSerializationFailed(message: "Not Valid JSON Format")
            }
            if isList {
                guard let listResponse: ListResponse<T> = ListResponse(data: json) else {
                    throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
                }
                if listResponse.code != ResponseCode.successResponseStatus {
                    try NetworkError.handleError(responseCode: listResponse.code, message: listResponse.message)
                }
                return (nil, listResponse)
            } else {
                guard let response: ModelResponse<T> = ModelResponse(data: json) else {
                    throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
                }
                if response.code != ResponseCode.successResponseStatus {
                    try NetworkError.handleError(responseCode: response.code, message: response.message)
                }
                return (response, nil)
            }
    }
}

/// 保证同一请求同一时间只请求一次(待完善)
private extension Network {
    func isSameRequest<API: TargetType & MoyaAddable>(_ api: API) -> Bool {
        let key = ResponseCache.uniqueKey(api)
        var result: Bool!
        barrierQueue.sync(flags: .barrier) {
            result = fetchRequestKeys.contains(key)
            if !result {
                fetchRequestKeys.append(key)
            }
        }
        return result
    }

    func cleanRequest<API: ElegantMayaProtocol>(_ api: API) {
        let key = ResponseCache.uniqueKey(api)
        _ = barrierQueue.sync(flags: .barrier) {
            fetchRequestKeys.removeFirst(where: { (string) -> Bool in
                key == string
            })
        }
    }
}
