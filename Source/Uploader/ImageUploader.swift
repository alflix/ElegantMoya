//
//  AlamofireHelper.swift
//  Matters
//
//  Created by ganguo on 2018/12/27.
//  Copyright © 2018年 Ganguo. All rights reserved.
//

import UIKit
import Alamofire

public typealias MultiUploadCallback = (Result<Any>?, DataResponse<Any>?) -> Void
public typealias UploadCallback = ( [Int: Bool], [DataResponse<Any>]?) -> Void

public enum UploadType {
    case multipartformdata
    case binary
}

public class ImageUploader {
    /// 上传多张图片 - 单次请求(multipartFormData)
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - compressSize: 压缩图片的 kb 限制值，<0 时不压缩
    ///   - server: 服务器地址（包含 baseURL）
    ///   - header: 请求 Header
    ///   - parameter: value 为文件，key 为 parameter
    ///   - method: 请求方法
    ///   - callback: Result：请求是否成功, DataResponse: 请求返回的 response
    static public func uploadMultiImageOnce(images: [UIImage],
                                            compressSize: Int = 1000,
                                            toServer server: String,
                                            header: HTTPHeaders? = nil,
                                            parameter: String = "any",
                                            method: HTTPMethod = .post,
                                            _ callback: @escaping MultiUploadCallback) {
        var result: Result<Any>?
        var dataResponses: DataResponse<Any>?
        let group = DispatchGroup()
        group.enter()
        Alamofire.upload(multipartFormData: { (formData) in
            for image in images {
                var imageData: Data!
                if compressSize > 0 {
                    imageData = image.imageCropAndResize(to: compressSize)
                } else {
                    imageData = image.jpegData(compressionQuality: 1) ?? Data()
                }
                formData.append(imageData, withName: parameter, fileName: "any.jpg", mimeType: "image/jpeg")
            }
        }, to: server,
           method: method,
           headers: header,
           encodingCompletion: { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    dataResponses = response
                    if let statusCode = response.response?.statusCode, statusCode == 200 {
                        result = .success(response)
                    } else {
                        result = .failure(response.error ?? AFError.ResponseValidationFailureReason.self as! Error)
                    }
                    group.leave()
                }
            case .failure:
                result = .failure(AFError.ResponseValidationFailureReason.self as! Error)
                group.leave()
            }
        })
        group.notify(queue: DispatchQueue.main) {
            callback(result, dataResponses)
        }
    }

    /// 上传多张图片 - 分次请求
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - uploadType: 上传类型
    ///   - compressSize: 压缩图片的 kb 限制值，<0 时不压缩
    ///   - server: 服务器地址（包含 baseURL）
    ///   - header: 请求 Header
    ///   - parameter: 请求参数
    ///   - method: 请求方法
    ///   - callback: [UIImage: Bool], key：上传的图片的 hashValue，value：是否成功, DataResponse: 请求的返回resonse 数组
    static public func uploadImage(images: [UIImage],
                                   uploadType: UploadType,
                                   compressSize: Int = 1000,
                                   toServer server: String,
                                   header: HTTPHeaders? = nil,
                                   parameter: String = "any",
                                   method: HTTPMethod = .post,
                                   _ callback: @escaping UploadCallback) {
        var imageMapRespone: [Int: Bool] = [:]
        var dataResponse: [DataResponse<Any>]?
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
                    formData.append(imageData, withName: parameter, fileName: "any.jpg", mimeType: "image/jpeg")
                }, to: server,
                   method: method,
                   headers: header,
                   encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                            dataResponse?.append(response)
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
                var header = header ?? [:]
                if !header.keys.contains("Content-Type") {
                    header["Content-Type"] = "image/jpeg"
                }
                Alamofire.upload(imageData,
                                 to: server,
                                 method: method,
                                 headers: header).validate(statusCode: 200..<300).responseJSON { (response) in
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
            callback(imageMapRespone, dataResponse)
        }
    }
}
