//
//  Network.swift
//  ElegantMoya
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import Moya

/// T: Response -> Model 的泛型
public class Network<T> where T: Codable {
    public init() { }

    /// 请求接口
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - view: api 所在请求的页面，用于显示 hud， 为空的话在 UIWindow 上调用（会卡住用户操作）
    ///   - completion: 结束返回数据闭包(缓存策略会影响闭包的调用时机和顺序)
    ///   - error: 错误返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func request<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        completion: NetworkSuccessBlock<T>? = nil,
        errorBlock: NetworkErrorBlock? = nil)
        -> Cancellable? {
            return request(api, in: view, comletion: completion, errorBlock: errorBlock)
    }

    // 用来处理只请求一次的栅栏队列
    private let barrierQueue = DispatchQueue(label: "com.Network.ElegantMoya", attributes: .concurrent)
    // 用来处理只请求一次的数组,保存请求的信息 唯一
    private var fetchRequestKeys = [String]()
}

private extension Network {
    /// 请求基类方法
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - view: api 所在请求的页面，用于显示 hud， 为空的话在 UIWindow 上调用（会卡住用户操作）
    ///   - comletion: 返回数据闭包
    ///   - errorBlock: 错误信息返回闭包
    func request<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        comletion: NetworkSuccessBlock<T>? = nil,
        errorBlock: NetworkErrorBlock? = nil)
        -> Cancellable? {
            // 同一请求正在请求直接返回
            if isSameRequest(api) { return nil }
            let successblock = { (isFromCache: Bool, shouldRevoke: Bool, response: Response) in
                DispatchQueue.main.async {
                    self.handleSuccessResponse(api, in: view, response: response, isFromCache: isFromCache,
                                               comletion: shouldRevoke ? comletion : nil, errorBlock: errorBlock)
                }
            }
            let checkIfCache: () -> Bool = {
                let cacheKey = ResponseCache.uniqueKey(api)
                if let responseStorage = ResponseCache.shared.responseStorage,
                    let response = try? responseStorage.object(forKey: cacheKey) {
                    successblock(true, true, response)
                    return true
                }
                return false
            }

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
            let fetchBackground = (cachePolicy == .returnCacheDataAndFetchBackground && hasCache)
            let provider = ElegantMoya.createProvider(api: api, showLoading: !fetchBackground, in: view)
            let cancellable = provider.request(api, callbackQueue: .global()) { (response) in
                // 请求完成移除
                self.cleanRequest(api)
                switch response {
                case .success(let response):
                    let shouldRevoke = !fetchBackground
                    successblock(false, shouldRevoke, response)
                case .failure(let error):
                    ShowHudHelper.showFail(api: api, message: error.errorDescription, view: view)
                    errorBlock?(NetworkError.moya(error))
                }
            }
            return cancellable
    }

    /// 处理成功的返回(业务上不一定是成功)
    func handleSuccessResponse<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        response: Response,
        isFromCache: Bool,
        comletion: NetworkSuccessBlock<T>? = nil,
        errorBlock: NetworkErrorBlock? = nil) {
        do {
            try response.filterSuccessfulStatusCodes()
            let json = try response.mapJSON()
            guard let responseBody = ResponseObject<T>(json: json) else {
                throw MoyaError.jsonMapping(response)
            }
            if responseBody.code != ElegantMoya.ResponseCode.success {
                errorBlock?(NetworkError.response(responseBody))
                ShowHudHelper.showFail(api: api, message: responseBody.message ?? ElegantMoya.ErrorMessage.networt, view: view)
                return
            }
            if !isFromCache && api.cachePolicy != .fetchIgnoringCacheData {
                ResponseCache.cacheData(api, data: response)
            }
            ShowHudHelper.showSuccess(api: api, view: view)
            if responseBody.isArray {
                if let data = responseBody.dataContent as? [Any] {
                    let keyPath = ElegantMoya.DataMapKeyPath.data + "." + ElegantMoya.DataMapKeyPath.content
                    let models = try response.map([T].self, atKeyPath: keyPath, using: jsonDeoder)
                    let page = try response.map(Pagination.self, atKeyPath: ElegantMoya.DataMapKeyPath.pagination, using: jsonDeoder)
                    responseBody.models = models
                    responseBody.page = page
                    comletion?(responseBody, isFromCache)
                } else {
                    let models = try response.map([T].self, atKeyPath: ElegantMoya.DataMapKeyPath.data, using: jsonDeoder)
                    responseBody.models = models
                    comletion?(responseBody, isFromCache)
                }
            } else {
                let model = try response.map(T.self, atKeyPath: ElegantMoya.DataMapKeyPath.data, using: jsonDeoder)
                responseBody.model = model
                comletion?(responseBody, isFromCache)
            }
        } catch let MoyaError.statusCode(response) {
            errorBlock?(NetworkError.moya(MoyaError.statusCode(response)))
            if (500...599).contains(response.statusCode) {
                ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.server, view: view)
                return
            }
            if response.statusCode == HTTPStatusCode.unauthorized.rawValue {
                ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.unauthorized, view: view)
                ElegantMoya.logoutClosure()
            }
        } catch let MoyaError.jsonMapping(response) {
            errorBlock?(NetworkError.moya(MoyaError.jsonMapping(response)))
            ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.serialization, view: view)
        } catch let MoyaError.objectMapping(error, response) {
            errorBlock?(NetworkError.moya(MoyaError.objectMapping(error, response)))
            ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.serialization, view: view)
        } catch {
            #if Debug
            fatalError("unkwnow error")
            #endif
        }
    }

    var jsonDeoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let dateFormat = ElegantMoya.Codable.dateFormat {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
        } else {
            decoder.dateDecodingStrategy = ElegantMoya.Codable.dateDecodingStrategy
        }
        return decoder
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

extension RangeReplaceableCollection {
    @discardableResult
    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let index = try firstIndex(where: predicate) else { return nil }
        return remove(at: index)
    }
}
