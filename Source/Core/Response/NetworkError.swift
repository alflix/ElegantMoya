//
//  NetworkError.swift
//  ElegantMoya
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation

/// 自定义错误类型（待完善）
///
/// - cache: 缓存错误
/// - loadFail: 加载错误
public enum ResponseStatusCode: Int {
    case cache = 230
    case loadFail = 700
}

/// 错误码
public struct ResponseCode {
    static let successResponseStatus = 0     // 接口成功调用
    static let forceLogoutError = 401       // 未登录或身份信息已过期
}

// 网络错误处理枚举
public enum NetworkError: Error {
    /// json解析失败
    case jsonSerializationFailed(message: String)
    /// json转字典失败
    case jsonToDictionaryFailed(message: String)
    /// 登录状态变化
    case loginStateIsexpired(message: String?)
    /// 服务器返回的错误
    case serverResponse(message: String?, code: Int)
    /// 自定义错误
    case exception(message: String)
}

public extension NetworkError {
    var message: String? {
        switch self {
        case let .serverResponse(msg, _):
            return msg
        default:
            return nil
        }
    }

    var code: Int {
        switch self {
        case let .serverResponse(_, code):
            return code
        default:
            return -1
        }
    }

    /// 处理错误信息
    static func handleError(responseCode: Int, message: String?) throws {
        switch responseCode {
        case ResponseCode.forceLogoutError:
            throw NetworkError.loginStateIsexpired(message: message)
        default:
            throw NetworkError.serverResponse(message: message, code: responseCode)
        }
    }
}
