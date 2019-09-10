//
//  AlamofireHelper.swift
//  Matters
//
//  Created by ganguo on 2018/12/27.
//  Copyright © 2018年 Ganguo. All rights reserved.
//

import UIKit
import Alamofire
import GGUI

public typealias MultiUploadCallback = (Result<Any>?, DataResponse<Any>?) -> Void
public typealias UploadCallback = ( [Int: Bool], [DataResponse<Any>]?) -> Void

public enum UploadType {
    case multipartformdata
    case binary
}

public class ImageUploader {
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

    /// 用于阿里云表单上传图片, 用 URLSession 重新请求
    /// 原因: https://developer.aliyun.com/ask/130042?spm=a2c6h.13159736
    static public func uploadImageWithParameters(image: UIImage,
                                   parameters: [String: Any],
                                   compressSize: CGFloat = 1000,
                                   toServer server: String,
                                   _ callback: @escaping UploadCallback) {
        var imageMapRespone: [Int: Bool] = [:]
        let imageData = image.jpegData(compressionQuality: compressSize)
        // 创建一个起到分割作用的boundary
        let boundary = "9431149156168"
        // 创建一个网络请求对象
        var request = URLRequest(url: URL(string: server)!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)

        // 从这里开始构造请求体
        //分界线 --AaB03x
        let startBoundary = "--\(boundary)"
        //结束符 AaB03x--
       let endBoundary = "\(startBoundary)--"
        // 存放参数的数组，后续好转成字符串，也就是请求体
        var body: String = ""
        // 拼接参数和boundary的临时变量
        var fileTmpStr = ""
        // 参数的集合的所有key的集合
        let keys = parameters.keys
        keys.forEach { (key) in
            body.append(contentsOf: "\(startBoundary)\r\n")
            body.append(contentsOf: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append(contentsOf: "\(parameters["\(key)"]!)\r\n")
        }
        body.append(contentsOf: "\(startBoundary)\r\n")
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"any.jpg\"\r\n")
        body.append(contentsOf: "Content-Type: image/jpeg\r\n\r\n")
        //声明结束符：--AaB03x--
        let end = "\r\n\(endBoundary)"
        var myRequestData = Data()
        // body -> utf8
        myRequestData.append(body.data(using: String.Encoding.utf8)!)
        myRequestData.append(imageData!)
        myRequestData.append(end.data(using: String.Encoding.utf8)!)
        // 设置HTTPHeader中Content-Type的值
        let content = "multipart/form-data; boundary=\(boundary)"
        request.setValue(content, forHTTPHeaderField: "Content-Type")
        // 设置Content-Length
        request.setValue("\(myRequestData.count)", forHTTPHeaderField: "Content-Length")
        //设置http body
        request.httpBody = myRequestData
        // http Method
        request.httpMethod = "POST"
        DPrint(body)
        DPrint(String(data: myRequestData, encoding: String.Encoding.utf8))
        //默认session配置
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let dataTask = session.dataTask(with: request) { (data, response, _) in
            if data != nil {
                do {
                    let rsponseStr = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    DPrint(rsponseStr)
                } catch {
                    // 请求失败
                    DPrint(String(data: data!, encoding: String.Encoding.utf8))
                    imageMapRespone[image.hashValue] = false
                }
                if let response = response as? HTTPURLResponse, [204, 205].contains(response.statusCode) {
                    // 请求成功
                    imageMapRespone[image.hashValue] = true
                } else {
                    // 请求失败
                    imageMapRespone[image.hashValue] = false
                }
                callback(imageMapRespone, nil)
            }
        }
        //请求开始
        dataTask.resume()
    }
}
