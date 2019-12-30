//
//  MoyaAddable.swift
//  ElegantMoya
//
//  Created by John on 2019/6/12.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation

/// 新增的协议
public protocol MoyaAddable {
    /// 缓存策略，默认为 fetchIgnoringCacheData，即不开启缓存
    var cachePolicy: CachePolicy? { get }
    /// 是否显示显示加载 loading，默认为 true
    var isShowHud: Bool { get }
    /// 是否显示失败的提示语(API 返回)，默认为 true
    var isShowFailHud: Bool { get }
    /// 成功时显示的提示语，为空时不显示。默认为空
    var successMessage: String? { get }
}

/// 默认实现
public extension MoyaAddable {
    var cachePolicy: CachePolicy? {
        return .fetchIgnoringCacheData
    }

    var isShowHud: Bool {
        return true
    }

    var isShowFailHud: Bool {
        return true
    }

    var successMessage: String? {
        return nil
    }
}
