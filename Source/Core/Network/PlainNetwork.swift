//
//  PlainNetwork.swift
//  ElegantMoya
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
    public func request<API: ElegantMayaProtocol>(
        _ api: API,
        completion: ResponseSuccessBlock? = nil,
        error: NetworkErrorBlock? = nil)
        -> Cancellable? {
            return request(api, comletion: completion, error: error)
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
    func request<API: ElegantMayaProtocol>(
        _ api: API,
        comletion: ResponseSuccessBlock? = nil,
        error: NetworkErrorBlock? = nil)
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
                    ShowHudHelper.showFail(api: api, message: networkError.message)
                    error?(networkError)
                }
            }
            let provider = ElegantMoya.createProvider(api: api)
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
    func handleSuccessResponse<API: ElegantMayaProtocol>(
        _ api: API,
        response: Response,
        comletion: ResponseSuccessBlock? = nil,
        error: NetworkErrorBlock? = nil) {
        do {
            try handleResponseData(api: api, data: response)
            guard let temp = comletion else { return }
            temp(response)
            ShowHudHelper.showSuccess(api: api)
        } catch let NetworkError.serverResponse(message, code) {
            ShowHudHelper.showFail(api: api, message: message)
            error?(NetworkError.serverResponse(message: message, code: code))
        } catch let NetworkError.loginStateIsexpired(message) {
            ElegantMoya.logoutClosure()
            ShowHudHelper.showFail(api: api, message: message)
            error?(NetworkError.loginStateIsexpired(message: message))
        } catch {
            #if Debug
            fatalError("unkwnow error")
            #endif
        }
    }

    /// 处理数据
    func handleResponseData<API: ElegantMayaProtocol>(api: API, data: Response)
        throws {
            guard let json = try? JSONSerialization.jsonObject(with: data.data, options: []) else {
                throw NetworkError.jsonSerializationFailed(message: "Not Valid JSON Format")
            }
            guard let response = BaseResponse(data: json) else {
                throw NetworkError.jsonToDictionaryFailed(message: "JSONSerialization error")
            }
            if response.code != ResponseCode.successResponseStatus {
                try NetworkError.handleError(responseCode: response.code, message: response.message)
            }
    }
}
