//
//  AlamofireHelper.swift
//  Matters
//
//  Created by ganguo on 2018/12/27.
//  Copyright © 2018年 Ganguo. All rights reserved.
//

import UIKit
import Alamofire

public typealias UploadCallback = ([Int: Bool]) -> Void

public enum UploadType {
    case multipartformdata
    case binary
}

public class ImageUploader {
    /// 上传多张图片  
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - uploadType: 上传类型
    ///   - compressSize: 压缩图片的 kb 限制值，<0 时不压缩
    ///   - server: 服务器地址（包含 baseURL）
    ///   - callback: [UIImage: Bool], key：上传的图片的 hashValue，value：是否成功
    static public func uploadImage(images: [UIImage],
                            uploadType: UploadType,
                            compressSize: Int = 1000,
                            toServer server: String,
                            _ callback: @escaping UploadCallback) {
        var imageMapRespone: [Int: Bool] = [:]
        let group = DispatchGroup()
        for image in images {
            group.enter()
            var imageData: Data!
            if compressSize > 0 {
                imageData = image.imageCropAndResize(to: compressSize)
            } else {
                imageData = image.jpegData(compressionQuality: 1) ?? Data()
            }

            switch uploadType {
            case .multipartformdata:
                Alamofire.upload(multipartFormData: { (formData) in
                    formData.append(imageData, withName: "any", fileName: "any.jpg", mimeType: "image/jpeg")
                }, to: server,
                   method: .put,
                   headers: nil,
                   encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                            if let statusCode = response.response?.statusCode, statusCode == 200 {
                                imageMapRespone[image.hashValue] = true
                            } else {
                                imageMapRespone[image.hashValue] = false
                            }
                            group.leave()
                        }
                    case .failure:
                        imageMapRespone[image.hashValue] = false
                        group.leave()
                    }
                })
            case .binary:
                let headers = ["Content-Type": "image/jpeg"]
                Alamofire.upload(imageData, to: server, method: .put, headers: headers).validate(statusCode: 200..<300).responseJSON { (response) in
                    if let statusCode = response.response?.statusCode, statusCode == 200 {
                        imageMapRespone[image.hashValue] = true
                    } else {
                        imageMapRespone[image.hashValue] = false
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            callback(imageMapRespone)
        }
    }
}
