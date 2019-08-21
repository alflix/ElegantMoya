//
//  Network.swift
//  Ganguo
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
import Moya
import Cache

/// T: Response -> Model 的泛型
public class Network<T> where T: Codable {
    public init() { }

    /// 请求普通接口
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - cachePolicy: 缓存策略
    ///   - completion: 结束返回数据闭包(缓存策略会影响闭包的调用时机和顺序)
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func request<API: TargetType & MoyaAddable>(
        _ api: API,
        cachePolicy: CachePolicy = .returnCacheDataAndFetch,
        completion: ((ModelResponse<T>?) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil)
        -> Cancellable? {
            return request(api,
                           cachePolicy: cachePolicy,
                           modelComletion: completion,
                           error: error)
    }

    /// 请求列表接口
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - completion: 结束返回数据闭包(缓存策略会影响闭包的调用时机和顺序)
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func requestList<API: TargetType & MoyaAddable>(
        _ api: API,
        cachePolicy: CachePolicy = .returnCacheDataAndFetch,
        completion: ((ListResponse<T>?) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil)
        -> Cancellable? {
            return request(api, cachePolicy: cachePolicy, modelListComletion: completion, error: error)
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
    func request<API: TargetType & MoyaAddable>(
        _ api: API,
        cachePolicy: CachePolicy = .returnCacheDataAndFetch,
        modelComletion: ((ModelResponse<T>?) -> Void)? = nil,
        modelListComletion: ((ListResponse<T>?) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil)
        -> Cancellable? {
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
                    self.showFail(api: api, message: networkError.message)
                    error?(networkError)
                }
            }
            let checkIfCache: () -> Bool = {
                if let cacheKey = api.cacheKey,
                    let responseStorage = ResponseCache.shared.responseStorage,
                    let response = try? responseStorage.object(forKey: cacheKey) {
                    successblock(true, response)
                    return true
                }
                return false
            }
            let provider = createProvider(api: api)
            var hasCache = false

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
    func handleSuccessResponse<API: TargetType & MoyaAddable>(
        _ api: API,
        response: Response,
        modelComletion: ((ModelResponse<T>?) -> Void)? = nil,
        modelListComletion: ((ListResponse<T>?) -> Void )? = nil,
        error: ((NetworkError) -> Void)? = nil) {
        do {
            if let temp = modelComletion {
                let modelResponse = try handleResponseData(isList: false, api: api, data: response)
                DispatchQueue.main.async {
                    self.cacheData(api, data: response)
                    temp(modelResponse.0)
                    self.showSuccess(api: api)
                }
            }
            if let temp = modelListComletion {
                let listResponse = try handleResponseData(isList: true, api: api, data: response)
                DispatchQueue.main.async {
                    self.cacheData(api, data: response)
                    temp(listResponse.1)
                    self.showSuccess(api: api)
                }
            }
        } catch let NetworkError.serverResponse(message, code) {
            showFail(api: api, message: message)
            error?(NetworkError.serverResponse(message: message, code: code))
        } catch let NetworkError.loginStateIsexpired(message) {
            ElegantMoya.logoutClosure()
            showFail(api: api, message: message)
            error?(NetworkError.loginStateIsexpired(message: message))
        } catch {
            #if Debug
            fatalError("unknown error")
            #endif
        }
    }

    /// 处理数据
    func handleResponseData<API: TargetType & MoyaAddable>(isList: Bool, api: API, data: Response)
        throws -> (ModelResponse<T>?, ListResponse<T>?) {
            guard let jsonAny = try? JSONSerialization.jsonObject(with: data.data, options: []) else {
                throw NetworkError.jsonSerializationFailed(message: "JSONSerialization error")
            }
            if isList {
                let listResponse: ListResponse<T>? = ListResponse(data: jsonAny)
                guard let temp = listResponse else {
                    throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
                }
                if temp.code != ResponseCode.successResponseStatus {
                    try handleCode(responseCode: temp.code, message: temp.message)
                }
                return (nil, temp)
            } else {
                let response: ModelResponse<T>? = ModelResponse(data: jsonAny)
                guard let temp = response else {
                    throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
                }
                if temp.code != ResponseCode.successResponseStatus {
                    try handleCode(responseCode: temp.code, message: temp.message)
                }
                return (temp, nil)
            }
    }

    /// 处理错误信息
    func handleCode(responseCode: Int, message: String?) throws {
        switch responseCode {
        case ResponseCode.forceLogoutError:
            throw NetworkError.loginStateIsexpired(message: message)
        default:
            throw NetworkError.serverResponse(message: message, code: responseCode)
        }
    }

    /// 缓存
    func cacheData<API: TargetType & MoyaAddable>( _ api: API, data: Response) {
        guard let cacheKey = api.cacheKey else { return }
        try? ResponseCache.shared.responseStorage?.setObject(data, forKey: cacheKey)
    }

    /// 创建moya请求类
    func createProvider<T: TargetType & MoyaAddable>(api: T) -> MoyaProvider<T> {
        let activityPlugin = NetworkActivityPlugin { (state, _) in
            DispatchQueue.main.async {
                switch state {
                case .began:
                    self.showLoading(api: api)
                case .ended:
                    self.hideLoading(api: api)
                }
            }
        }

        // 输出日志
        let loggerPlugin = NetworkLoggerPlugin(verbose: true, responseDataFormatter: { (data: Data) -> Data in
            do {
                // Data 转 JSON
                let dataAsJSON = try JSONSerialization.jsonObject(with: data)
                // JSON 转 Data，格式化输出。
                let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
                return prettyData
            } catch {
                return data
            }
        })
        if let token = ElegantMoya.tokenClosure() {
            let authPlugin = AccessTokenPlugin { token }
            return MoyaProvider<T>(plugins: [activityPlugin, loggerPlugin, authPlugin])
        }
        return MoyaProvider<T>(plugins: [activityPlugin, loggerPlugin])
    }
}

/// 保证同一请求同一时间只请求一次
private extension Network {
    func cleanRequest<API: TargetType & MoyaAddable>(_ api: API) {
        switch api.task {
        case let .requestParameters(parameters, _):
            let key = api.path + parameters.description
            _ = barrierQueue.sync(flags: .barrier) {
                fetchRequestKeys.removeFirst(where: { (string) -> Bool in
                    key == string
                })
            }
        default:
            // 不会调用
            ()
        }
    }
}

private extension Network {
    func showLoading<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.showLoadingHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func hideLoading<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.hideHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func showSuccess<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud, let message = api.successMessage, let window = UIApplication.shared.windows.first {
            window.showSuccessHud(title: message)
        }
    }

    func showFail<API: TargetType & MoyaAddable>(api: API, message: String?) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.showFailHud(title: message ?? ElegantMoya.ErrorMessage.networt)
        }
    }
}
