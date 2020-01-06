//
//  ShowHudHelper.swift
//  ElegantMoya
//
//  Created by John on 2019/9/3.
//

import UIKit
import Moya

// TODO: 支持插件化
public struct ShowHudHelper {
    static func showLoading<API: ElegantMayaProtocol>(api: API, view: UIView? = nil) {
        guard api.isShowHud else { return }
        if let view = view ?? UIApplication.shared.windows.first {
            view.showLoadingHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    static func hideLoading<API: ElegantMayaProtocol>(api: API, view: UIView? = nil) {
        guard api.isShowHud else { return }
        if let view = view ?? UIApplication.shared.windows.first {
            view.hideHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    static func showSuccess<API: ElegantMayaProtocol>(api: API, view: UIView? = nil) {
        if let view = view ?? UIApplication.shared.windows.first, let message = api.successMessage {
            view.hideHud()
            view.showSuccessHud(title: message)
        }
    }

    static func showFail<API: ElegantMayaProtocol>(api: API, message: String?, view: UIView? = nil) {
        guard api.isShowFailHud else { return }
        if let view = view ?? UIApplication.shared.windows.first, let message = message {
            view.hideHud()
            view.showFailHud(title: message)
        }
    }
}
