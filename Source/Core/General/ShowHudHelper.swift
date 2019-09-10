//
//  ShowHudHelper.swift
//  ElegantMoya
//
//  Created by John on 2019/9/3.
//

import UIKit
import Moya

struct ShowHudHelper {
    static func showLoading<API: ElegantMayaProtocol>(api: API) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.showLoadingHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    static func hideLoading<API: ElegantMayaProtocol>(api: API) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.hideHud()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    static func showSuccess<API: ElegantMayaProtocol>(api: API) {
        if api.isShowHud, let message = api.successMessage, let window = UIApplication.shared.windows.first {
            window.showSuccessHud(title: message)
        }
    }

    static func showFail<API: ElegantMayaProtocol>(api: API, message: String?) {
        if api.isShowHud, let window = UIApplication.shared.windows.first {
            window.showFailHud(title: message ?? ElegantMoya.ErrorMessage.networt)
        }
    }
}
