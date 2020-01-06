//
//  PlainNetwork.swift
//  ElegantMoya
//
//  Created by John on 2019/6/15.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import Moya

public class PlainNetwork {
    public init() {}

    /// 请求普通接口（不需要数据解析，缓存，只要http code == 200， code == 0 即回调 completion，否则回调 error）
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - view: api 所在请求的页面，用于显示 hud， 为空的话在 UIWindow 上调用（会卡住用户操作）
    ///   - completion: 结束返回数据闭包
    ///   - errorBlock: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    public func request<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        completion: ResponseSuccessBlock? = nil,
        errorBlock: NetworkErrorBlock? = nil)
        -> Cancellable? {
            return request(api, in: view, comletion: completion, errorBlock: errorBlock)
    }

    // 用来处理只请求一次的栅栏队列
    private let barrierQueue = DispatchQueue(label: "com.PlainNetwork.ElegantMoya", attributes: .concurrent)
    // 用来处理只请求一次的数组,保存请求的信息 唯一
    private var fetchRequestKeys = [String]()
}

private extension PlainNetwork {
    /// 请求基类方法
    ///
    /// - Parameters:
    ///   - api: 根据Moya定义的接口
    ///   - comletion: 普通接口返回数据闭包
    ///   - errorBlock: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    func request<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        comletion: ResponseSuccessBlock? = nil,
        errorBlock: NetworkErrorBlock? = nil)
        -> Cancellable? {
            // 同一请求正在请求直接返回
            if isSameRequest(api) {
                return nil
            }
            let provider = ElegantMoya.createProvider(api: api, showLoading: true, in: view)
            let cancellable = provider.request(api, callbackQueue: .global()) { (response) in
                // 请求完成移除
                self.cleanRequest(api)
                switch response {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.handleSuccessResponse(api, in: view, response: response, comletion: comletion, errorBlock: errorBlock)
                    }
                case .failure(let error):
                    switch error {
                    case let MoyaError.underlying(moyaError, _):
                        // underlying 这个类型的错误比较迷
                        break
                    default:
                        ShowHudHelper.showFail(api: api, message: error.errorDescription, view: view)
                    }
                    DispatchQueue.main.async {
                        errorBlock?(NetworkError.moya(error))
                    }
                }
            }
            return cancellable
    }

    /// 处理成功的返回
    func handleSuccessResponse<API: ElegantMayaProtocol>(
        _ api: API,
        in view: UIView? = nil,
        response: Response,
        comletion: ResponseSuccessBlock? = nil,
        errorBlock: NetworkErrorBlock? = nil) {
        do {
            try response.filterSuccessfulStatusCodes()
            let json = try response.mapJSON()
            guard let responseBody = ResponseBody(json: json) else {
                throw MoyaError.jsonMapping(response)
            }
            if responseBody.code != ElegantMoya.ResponseCode.success {
                throw NetworkError.response(responseBody)
            }
            comletion?(responseBody)
            ShowHudHelper.showSuccess(api: api, view: view)
        } catch let NetworkError.response(responseBody) {
            errorBlock?(NetworkError.response(responseBody))
            if responseBody.code == HTTPStatusCode.unauthorized.rawValue {
                ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.unauthorized, view: view)
                ElegantMoya.logoutClosure()
            }
            ShowHudHelper.showFail(api: api, message: responseBody.message ?? ElegantMoya.ErrorMessage.networt, view: view)
        } catch let MoyaError.statusCode(response) {
            errorBlock?(NetworkError.moya(MoyaError.statusCode(response)))
            if (500...599).contains(response.statusCode) {
                ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.server, view: view)
                return
            }
            if response.statusCode == HTTPStatusCode.unauthorized.rawValue {
                ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.unauthorized, view: view)
                ElegantMoya.logoutClosure()
                return
            }
        } catch let MoyaError.jsonMapping(response) {
            errorBlock?(NetworkError.moya(MoyaError.jsonMapping(response)))
            ShowHudHelper.showFail(api: api, message: ElegantMoya.ErrorMessage.serialization, view: view)
        } catch {
            assert(true, "unkwnow error")
        }
    }
}

/// TODO：(待完善) 保证同一请求同一时间只请求一次
private extension PlainNetwork {
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
