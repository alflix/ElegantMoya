//
//  ElegantMoya.swift
//  ElegantMoya
//
//  Created by John on 2019/7/29.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
import Moya

public typealias ResponseSuccessBlock = (Response) -> Void
public typealias NetworkSuccessBlock<T: Codable> = (ModelResponse<T>?) -> Void
public typealias NetworkListSuccessBlock<T: Codable> = (ListResponse<T>?) -> Void
public typealias NetworkErrorBlock = (NetworkError) -> Void
public typealias ElegantMayaProtocol = TargetType & MoyaAddable

/// ElegantMoya 的配置，通常在 AppDelegate 提供
public struct ElegantMoya {
    /// 错误信息
    public enum ErrorMessage {
        /// 服务器出错
        public static var server: String = "服务器出错"
        /// 网络错误
        public static var networt: String = "网络错误"
    }

    /// 通过 AccessTokenPlugin 方式的 header 需要获取 token，由 AccountManager 提供 
    public static var tokenClosure: () -> String? = { return nil }

    /// 接口 401，AccountManager 需要处理下线 
    public static var logoutClosure: () -> Void = { }
}

extension ElegantMoya {
    /// 创建moya请求类    
    static func createProvider<T: ElegantMayaProtocol>(api: T) -> MoyaProvider<T> {
        let activityPlugin = NetworkActivityPlugin { (state, _) in
            DispatchQueue.main.async {
                switch state {
                case .began:
                    ShowHudHelper.showLoading(api: api)
                case .ended:
                    ShowHudHelper.hideLoading(api: api)
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
