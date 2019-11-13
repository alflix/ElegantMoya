//
//  ElegantMoya.swift
//  ElegantMoya
//
//  Created by John on 2019/7/29.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import Moya

public typealias ResponseSuccessBlock = (ResponseBody) -> Void
public typealias NetworkSuccessBlock<T: Codable> = (_ data: ResponseObject<T>, _ isCache: Bool) -> Void
public typealias NetworkErrorBlock = (NetworkError) -> Void
public typealias ElegantMayaProtocol = TargetType & MoyaAddable

/// ElegantMoya 的配置，通常在 AppDelegate 提供
public struct ElegantMoya {
    /// 与后台协商的 Response body 的状态码
    public enum ResponseCode {
        public static var success = 0     // 接口成功调用
        public static var fail = -1       // 失败，具体失败原因在 HTTPStatusCode 或 message 中有进一步说明
    }

    /// 自定义错误信息
    public enum ErrorMessage {
        /// 服务器出错 500~599 http code
        public static var server: String = "服务器出错"
        /// 授权错误 401 http code
        public static var unauthorized: String = "已退出登录"
        /// http code == 200，但 Response body 的 code ！= ResponseCode.success, Response body 的 message 为空时显示的默认值
        public static var networt: String = "网络错误"
        /// http code == 200，但数据解析错误
        public static var serialization: String = "数据解析错误"
    }

    /// 自定义解析 Response body 的 KeyPath，以常用的为例子
    /*
     无分页
     {
       "status": "success",
       "data": [
         {
           "id": 7,
           "abbr": "AU",
           "chinese": "澳大利亚",
           "code": "61"
         },
         {
           "id": 8,
           "abbr": "AT",
           "chinese": "奥地利",
           "code": "43"
         }
       ],
       "message": "",
       "code": 0
     }
     有分页
     {
       "status": "success",
       "data": {
         "pagination": {
           "page": 1,
           "size": 10,
           "total": 1,
           "last": 1
         },
         "content": [
           {
             "id": 7,
             "abbr": "AU",
             "chinese": "澳大利亚",
             "code": "61"
           }
         ],
         "extra": null
       },
       "message": "",
       "code": 0
     }

     */
    public enum DataMapKeyPath {
        // 自定义 code
        public static var code: String = "code"
        // 返回的提示消息
        public static var message: String = "message"
        /// 无分页时其 data
        public static var data: String = "data"
        /// 有分页时其 data
        public static var content: String = "content"
        /// 有分页时其分页 
        public static var pagination: String = "data.pagination"
    }

    /// Codable 配置
    public enum Codable {
        /// 日期的格式
        public static var dateFormat: String?
        /// 日期 Decode 策略，如果 dateFormat 不为空，会以 dateFormat 创建的 formatted(DateFormatter) 为准，即该设置会被忽略
        public static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .millisecondsSince1970
        /// 日期 Encode 策略，如果 dateFormat 不为空，会以 dateFormat 创建的 formatted(DateFormatter) 为准，即该设置会被忽略
        public static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .millisecondsSince1970
    }

    /// 通过 AccessTokenPlugin 方式的 header 需要获取 token，由 AccountManager 提供 
    public static var tokenClosure: () -> String? = { return nil }

    /// 接口 401，AccountManager 需要处理下线 
    public static var logoutClosure: () -> Void = { }
}

public extension ElegantMoya {
    /// 创建moya请求类    
    static func createProvider<T: ElegantMayaProtocol>(api: T,
                                                       showLoading: Bool = true,
                                                       in view: UIView? = nil) -> MoyaProvider<T> {
        let activityPlugin = NetworkActivityPlugin { (state, _) in
            if showLoading {
                DispatchQueue.main.async {
                    switch state {
                    case .began:
                        ShowHudHelper.showLoading(api: api, view: view)
                    case .ended:
                        ShowHudHelper.hideLoading(api: api, view: view)
                    }
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
