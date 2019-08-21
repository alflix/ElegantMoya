//
//  File.swift
//  Ganguo
//
//  Created by John on 2019/6/11.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation

// 分页
public struct Pagination: Codable {
    /// 第几页(起始页为1)
    public var page: Int
    /// 每页显示的总数
    public var size: Int
    /// 最后一页的页码
    public var last: Int
    /// 总数
    public var total: Int

    static public func pageParameters(page: Int?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        if let page = page {
            parameters["page"] = page
            parameters["size"] = 20
        }
        return parameters
    }

    static public func pageParameters(originalParameters: inout [String: Any], page: Int?) {
        if let page = page {
            originalParameters["page"] = page
            originalParameters["size"] = 20
        }
    }
}

public class BaseResponse {
    public var code: Int {
        guard let temp = json["code"] as? Int else { return -1 }
        return temp
    }

    public var message: String? {
        guard let temp = json["message"] as? String else { return nil }
        return temp
    }

    public var jsonData: Any? {
        guard let temp = json["data"] else { return nil }
        return temp
    }

    public var dataContent: [Any]? {
        if let jsonData = jsonData as? [String: Any], let dataContent = jsonData["content"] as? [Any] {
            return dataContent
        }
        return nil
    }

    public var pagination: [String: Any]? {
        if let jsonData = jsonData as? [String: Any], let pagination = jsonData["pagination"] as? [String: Any] {
            return pagination
        }
        return nil
    }

    let json: [String: Any]

    init?(data: Any) {
        guard let temp = data as? [String: Any] else { return nil }
        self.json = temp
    }
}

public class ListResponse<T>: BaseResponse where T: Codable {
    public var datas: [T]? {
        guard code == 0 else { return nil }
        if page == nil {
            if let jsonData = jsonData as? [Any] {
                do {
                    return try [T](from: jsonData)
                } catch {
                    #if Debug
                    fatalError("JSONSerialization error")
                    #endif
                }
            }
        } else {
            if let jsonData = dataContent {
                do {
                    return try [T](from: jsonData)
                } catch {
                    #if Debug
                    fatalError("JSONSerialization error")
                    #endif
                }
            }
        }
        return nil
    }

    public var page: Pagination? {
        guard code == 0, let pagination = pagination else {
            return nil
        }
        do {
            return try Pagination(from: pagination)
        } catch {
            #if Debug
            fatalError("JSONSerialization error")
            #else
            return nil
            #endif
        }
    }
}

public class ModelResponse<T>: BaseResponse where T: Codable {
    public var data: T? {
        guard code == 0, let tempJSONData = jsonData else {
            return nil
        }
        do {
            return try T(from: tempJSONData)
        } catch {
            #if Debug
            fatalError("JSONSerialization error")
            #else
            return nil
            #endif
        }
    }
}
