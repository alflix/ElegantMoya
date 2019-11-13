//
//  ResponseCache.swift
//  ElegantMoya
//
//  Created by John on 2019/6/12.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import Cache
import Moya

/// 缓存策略
public enum CachePolicy {
    /// 默认，只拉取数据（要求显示最新数据，不显示缓存的时候使用）
    case fetchIgnoringCacheData
    /// 返回缓存，并且拉取数据（常用于列表页，先显示缓存给用户，再拉取数据，注意会有2个回调）
    case returnCacheDataAndFetch
    /// 返回缓存，并且默默地拉取数据（如果缓存已经有回调了，拉取数据完成后没有回调）
    case returnCacheDataAndFetchBackground
    /// 返回缓存，如果没有缓存的话，拉取数据（用于较固定的数据，例如后台返回的城市列表数据）
    case returnCacheDataElseFetch
    /// 只返回缓存（较少用）
    case returnCacheDataDontFetch
}

fileprivate extension TransformerFactory {
    static func forResponse<T: Moya.Response>(_ type: T.Type) -> Transformer<T> {
        let toData: (T) throws -> Data = { $0.data }
        let fromData: (Data) throws -> T = {
            T(statusCode: CustomCode.cache.rawValue, data: $0)
        }
        return Transformer<T>(toData: toData, fromData: fromData)
    }
}

private struct CacheName {
    static let MoyaResponse = "cache.com.MoyaResponse"
}

public struct ResponseCache {
    public static let shared = ResponseCache()
    private init() {}

    let responseStorage = try? Storage<Moya.Response>(
        diskConfig: DiskConfig(name: CacheName.MoyaResponse),
        memoryConfig: MemoryConfig(),
        transformer: TransformerFactory.forResponse(Moya.Response.self)
    )

    /// 清除所有 API 缓存
    public func removeAllCache() {
        try? responseStorage?.removeAll()
    }

    /// 清除 API 缓存
    public func removeCache<T: ElegantMayaProtocol>(api: T) {
        let cacheKey = ResponseCache.uniqueKey(api)
        try? responseStorage?.removeObject(forKey: cacheKey)
    }

    static func cacheData<API: ElegantMayaProtocol>(_ api: API, data: Response) {
        var shouldCache: Bool = true
        switch api.task {
        case let .requestParameters(parameters, _):
            if let page = parameters["page"] as? Int, page > Pagination.PageSetting.firstPage {
                shouldCache = false
            }
        case let .requestCompositeData(bodyData, urlParameters):
            if let page = urlParameters["page"] as? Int, page > Pagination.PageSetting.firstPage {
                shouldCache = false
            }
        case let .requestCompositeParameters(bodyParameters, bodyEncoding, urlParameters):
            if let page = bodyParameters["page"] as? Int, page > Pagination.PageSetting.firstPage {
                shouldCache = false
            }
            if let page = urlParameters["page"] as? Int, page > Pagination.PageSetting.firstPage {
                shouldCache = false
            }
        default:
            ()
        }
        guard shouldCache else { return }
        let cacheKey = ResponseCache.uniqueKey(api)
        print("cache: \(cacheKey)")
        try? ResponseCache.shared.responseStorage?.setObject(data, forKey: cacheKey)
    }

    /// API 缓存的唯一码
    static func uniqueKey<API: ElegantMayaProtocol>(_ api: API) -> String {
        switch api.task {
        case let .requestParameters(parameters, _):
            return api.path + parameters.sorted(by: { $0.key > $1.key }).description
        case let .requestCompositeData(bodyData, urlParameters):
            return api.path + urlParameters.sorted(by: { $0.key > $1.key }).description + String(bodyData.hashValue)
        case let .requestCompositeParameters(bodyParameters, bodyEncoding, urlParameters):
            return api.path + urlParameters.sorted(by: { $0.key > $1.key }).description + bodyParameters.sorted(by: { $0.key > $1.key }).description
        default:
            return api.path
        }
    }
}
