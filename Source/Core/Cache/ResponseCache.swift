//
//  ResponseCache.swift
//  CircleQ
//
//  Created by John on 2019/6/12.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
import Cache
import Moya

public enum ResponseStatusCode: Int {
    case cache = 230
    case loadFail = 700
}

public extension TransformerFactory {
    static func forResponse<T: Moya.Response>(_ type: T.Type) -> Transformer<T> {
        let toData: (T) throws -> Data = { $0.data }
        let fromData: (Data) throws -> T = {
            T(statusCode: ResponseStatusCode.cache.rawValue, data: $0)
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

    public func removeAllCache() {
        try? responseStorage?.removeAll()
    }
}
