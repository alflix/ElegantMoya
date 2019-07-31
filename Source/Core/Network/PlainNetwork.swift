//
//  PlainNetwork.swift
//  CircleQ
//
//  Created by John on 2019/6/15.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
import Moya

public class PlainNetwork {
    public init() { }

    /// 请求普通接口（不包含数据解析和缓存）
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - completion: 结束返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func request<API: TargetType & MoyaAddable>(
        _ api: API,
        completion: ((Response) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil)
        -> Cancellable? {
            return request(api, comletion: completion, error: error)
    }

    /// 移除 API 缓存，适用于 Network
    public func removeCache<API: TargetType & MoyaAddable>(_ api: API) {
        guard let cacheKey = api.cacheKey else { return }
        try? ResponseCache.shared.responseStorage?.removeObject(forKey: cacheKey)
    }
}

private extension PlainNetwork {
    /// 请求基类方法
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - comletion: 普通接口返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    func request<API: TargetType & MoyaAddable>(
        _ api: API,
        comletion: ((Response) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil)
        -> Cancellable? {
            let successBlock = { (response: Response) in
                DispatchQueue.main.async {
                    if let temp = comletion {
                        self.handleSuccessResponse(api, response: response, comletion: temp, error: error)
                    }
                }
            }
            let errorBlock = { (networkError: NetworkError) in
                DispatchQueue.main.async {
                    self.showFail(api: api, message: networkError.message)
                    error?(networkError)
                }
            }
            let provider = createProvider(api: api)
            let cancellable = provider.request(api, callbackQueue: .global(), progress: { (_) in
            }) { (response) in
                switch response {
                case .success(let response):
                    successBlock(response)
                case .failure:
                    errorBlock(NetworkError.exception(message: ElegantMoya.ErrorMessage.server))
                }
            }
            return cancellable
    }

    /// 处理成功的返回
    func handleSuccessResponse<API: TargetType & MoyaAddable>(
        _ api: API,
        response: Response,
        comletion: ((Response) -> Void)? = nil,
        error: ((NetworkError) -> Void)? = nil) {
        switch api.task {
        case .uploadMultipart, .requestParameters, .requestPlain:
            do {
                if let temp = comletion {
                    try handleResponseData(api: api, data: response)
                    temp(response)
                    showSuccess(api: api)
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
                fatalError("unkwnow error")
                #endif
            }
        default:
            ()
        }
    }

    /// 处理数据
    func handleResponseData<API: TargetType & MoyaAddable>(api: API, data: Response)
        throws {
            guard let jsonAny = try? JSONSerialization.jsonObject(with: data.data, options: []) else {
                throw NetworkError.jsonSerializationFailed(message: "JSONSerialization error")
            }
            let response = BaseResponse(data: jsonAny)
            guard let temp = response else {
                throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
            }
            if temp.code != ResponseCode.successResponseStatus {
                try handleCode(responseCode: temp.code, message: temp.message)
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

        // MARK: - 输出网络日志
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

private extension PlainNetwork {
    func showLoading<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud {
            if let window = UIApplication.shared.windows.first { window.showLoadingHud() }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func hideLoading<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud {
            if let window = UIApplication.shared.windows.first { window.hideHud() }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func showSuccess<API: TargetType & MoyaAddable>(api: API) {
        if api.isShowHud, let message = api.successMessage {
            if let window = UIApplication.shared.windows.first {
                window.showSuccessHud(title: message)
            }
        }
    }

    func showFail<API: TargetType & MoyaAddable>(api: API, message: String?) {
        if api.isShowHud {
            if let window = UIApplication.shared.windows.first {
                window.showFailHud(title: message ?? ElegantMoya.ErrorMessage.networt)
            }
        }
    }
}
