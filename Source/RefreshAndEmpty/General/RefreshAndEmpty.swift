//
//  RefreshAndEmpty.swift
//  Alamofire
//
//  Created by John on 2019/7/29.
//

import Foundation

public struct RefreshAndEmpty {
    /// 为空默认显示/错误信息
    public enum DefaultSetting {
        /// 为空默认显示图片
        public static var emptyImage: UIImage?
        /// 为空默认显示文字
        public static var emptyTitle: String?
        /// 为空视图在 View 中显示的 offset，view.height 的比例值，例如 -4:往上移动 view.height/4 的高度
        public static var verticalOffsetProportion: CGFloat?
        /// 为空默认显示文字的属性
        public static var titleAttributes: [NSAttributedString.Key: Any] = defaultTitleAttributes()
        /// 用来显示加载数据失败后的视图
        public static var loadFailedClosure: (_ refresh: @escaping () -> Void) -> UIView? = { _ in return nil }

        private static func defaultTitleAttributes() -> [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.black,
                                                             .font: UIFont.systemFont(ofSize: 14)]
            return attributes
        }
    }
}
