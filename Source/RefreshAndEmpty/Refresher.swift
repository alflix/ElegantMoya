//
//  Refresher.swift
//  Matters
//
//  Created by John on 2019/1/13.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import UIKit
import PullToRefreshKit

public class Refresher: UIView, RefreshableHeader {
    private let circleLayer = CAShapeLayer()
    private let strokeColor = UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpCircleLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        circleLayer.position = CGPoint(x: width/2, y: height/2 + 14)
    }

    func setUpCircleLayer() {
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: 11, y: 11),
                                      radius: 11.0,
                                      startAngle: -CGFloat.pi/2,
                                      endAngle: CGFloat.pi/2.0 * 3.0,
                                      clockwise: true)
        circleLayer.path = bezierPath.cgPath
        circleLayer.strokeColor = strokeColor.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeStart = 0
        circleLayer.strokeEnd = 0
        circleLayer.lineWidth = 3.0
        circleLayer.lineCap = CAShapeLayerLineCap.round
        circleLayer.bounds = CGRect(x: 0, y: 0, width: 22, height: 22)
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(circleLayer)
    }

    /// MARK: - RefreshableHeader -
    public func heightForHeader() -> CGFloat {
        return 88
    }

    public func heightForFireRefreshing() -> CGFloat {
        return 60.0
    }

    public func heightForRefreshingState() -> CGFloat {
        return 60.0
    }

    public func percentUpdateDuringScrolling(_ percent: CGFloat) {
        let adjustPercent = max(min(1.0, percent), 0.0)
        circleLayer.strokeEnd = 0.75 * adjustPercent
    }

    public func didBeginRefreshingState() {
        circleLayer.strokeEnd = 0.75
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.toValue = NSNumber(value: Double.pi * 2.0)
        rotateAnimation.duration = 1
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = 10000000
        circleLayer.add(rotateAnimation, forKey: "rotate")
    }

    public func didBeginHideAnimation(_ result: RefreshResult) {
        transitionWithOutAnimation {
            circleLayer.strokeEnd = 0
        }
        circleLayer.removeAllAnimations()
    }

    public func didCompleteHideAnimation(_ result: RefreshResult) {
        transitionWithOutAnimation {
            circleLayer.strokeEnd = 0
        }
    }

    func transitionWithOutAnimation(_ clousre:() -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        clousre()
        CATransaction.commit()
    }
}
