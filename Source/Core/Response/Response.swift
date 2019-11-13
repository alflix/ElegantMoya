//
//  File.swift
//  ElegantMoya
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import Moya

public class ResponseBody {
    public let json: [String: Any]

    init?(json: Any) {
        guard let temp = json as? [String: Any] else { return nil }
        self.json = temp
    }
}

public extension ResponseBody {
    public var code: Int {
        guard let temp = json[ElegantMoya.DataMapKeyPath.code] as? Int else { return ElegantMoya.ResponseCode.fail }
        return temp
    }

    public var message: String? {
        guard let temp = json[ElegantMoya.DataMapKeyPath.message] as? String else { return nil }
        return temp
    }

    public var data: Any? {
        guard let temp = json[ElegantMoya.DataMapKeyPath.data] else { return nil }
        return temp
    }

    public var dataContent: [Any]? {
        guard let data = data as? [String: Any], let temp = data[ElegantMoya.DataMapKeyPath.content] as? [Any] else { return nil }
        return temp
    }

    public var isArray: Bool {
        if data is [Any] || dataContent is [Any] {
            return true
        }
        return false
    }
}

public class ResponseObject<T>: ResponseBody where T: Codable {
    public var model: T?
    public var models: [T]?
    public var page: Pagination?
}

// 网络错误处理枚举
public enum NetworkError: Error {
    /// ResponseBody 返回的错误
    case response(ResponseBody)
    /// moya 类型的错误（包含解析问题，http code 错误等）
    case moya(MoyaError)
}

public extension NetworkError {
    /// Depending on error type, returns a `Response` object.
    var response: ResponseBody? {
        switch self {
        case .response(let response): return response
        case .moya: return nil
        }
    }

    var moyaError: MoyaError? {
        switch self {
        case .response: return nil
        case .moya(let error): return error
        }
    }

    var message: String? {
        switch self {
        case .response(let response): return response.message
        case .moya(let error): return error.errorDescription
        }
    }
}

// 分页 TODO：可定制
public struct Pagination: Codable {
    /// 第几页(起始页为1)
    public var page: Int
    /// 每页显示的总数
    public var size: Int
    /// 最后一页的页码
    public var last: Int
    /// 总数
    public var total: Int

    /// 分页设置
    public enum PageSetting {
        /// 第一页
        public static var firstPage: Int = 1
        /// 页数
        public static var pageSize: Int = 20
    }
}

public extension Pagination {
    static public func pageParameters(page: Int?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        if let page = page {
            parameters["page"] = page
            parameters["size"] = PageSetting.pageSize
        }
        return parameters
    }

    static public func pageParameters(originalParameters: inout [String: Any], page: Int?) {
        if let page = page {
            originalParameters["page"] = page
            originalParameters["size"] = PageSetting.pageSize
        }
    }
}
