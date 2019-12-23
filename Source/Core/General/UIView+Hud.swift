//
//  UIView+Hud.swift
//  ElegantMoya
//
//  Created by John on 2019/4/10.
//  Copyright © 2019 ElegantMoya. All rights reserved.
//

import Foundation
import MBProgressHUD

extension UIView {
    /// 显示 loading 的转圈
    ///
    /// - Parameters:
    ///   - title: 标题文案，eg：正在加载，默认为空
    func showLoadingHud(title: String? = "") {
        DispatchQueue.main.async {
            let progressHUD = MBProgressHUD.showAdded(to: self, animated: true)
            progressHUD.mode = .indeterminate
            progressHUD.label.text = title
        }
    }

    /// 显示带图片的成功提示弹窗
    /// 可在 Hud.successImage 设置统一的失败显示图片
    /// - Parameter title: 成功提示弹窗文案
    ///   - completion: 弹窗消失的回调
    func showSuccessHud(title: String, completion: (() -> Void)? = nil) {
        showMessageHud(title: title,
                       hideAfter: 1.5,
                       completion: completion)
    }

    /// 显示带图片的失败提示弹窗
    /// 可在 Hud.failImage 设置统一的失败显示图片
    /// - Parameter title: 失败提示弹窗文案
    ///   - completion: 弹窗消失的回调
    func showFailHud(title: String, completion: (() -> Void)? = nil) {
        showMessageHud(title: title,
                       hideAfter: 1.5,
                       completion: completion)
    }

    /// 显示提示弹窗
    ///
    /// - Parameters:
    ///   - title: 标题文案，eg：已发送，默认为空
    ///   - image: 图片，eg: ☑️，默认不显示
    ///   - time: 弹窗消失的时间，默认为 1.5s，可在 1.5 统一设置
    ///   - completion: 弹窗消失的回调
    func showMessageHud(title: String? = "",
                        image: UIImage? = nil,
                        hideAfter time: TimeInterval? = 1.5,
                        completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: self, animated: false)
            if let image = image {
                hud.mode = .customView
                hud.customView = UIImageView(image: image) //自定义视图显示图片
            } else {
                hud.mode = .text
                hud.detailsLabel.text = title
            }
            hud.hide(animated: false, afterDelay: time ?? 1.5)
            hud.completionBlock = completion
        }
    }

    /// 隐藏弹窗
    func hideHud() {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self, animated: true)
        }
    }
}
