//
//  MoyaAddable.swift
//  Ganguo
//
//  Created by John on 2019/6/12.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation

/// 新增的协议
public protocol MoyaAddable {
    /// 缓存 key，为空时不开启缓存功能
    var cacheKey: String? { get }
    /// true 的话，会自动显示加载 loading 和服务器返回的错误提示语，和自定义显示的 successMessage
    var isShowHud: Bool { get }
    /// 成功时显示的提示语（同时需要 isShowHud 为 true），为空时不显示
    var successMessage: String? { get }
}

/// 默认实现
public extension MoyaAddable {
    var cacheKey: String? {
        return nil
    }

    var isShowHud: Bool {
        return false
    }

    var successMessage: String? {
        return nil
    }
}
