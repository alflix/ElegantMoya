//
//  ElegantMoya.swift
//  Demo
//
//  Created by John on 2019/7/29.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import Foundation
@_exported import GGUI

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
