//
//  VideoUploader.swift
//  Alamofire
//
//  Created by Romint on 2019/8/8.
//

import UIKit
import AVKit
import Alamofire

public typealias VideoUploadCallback = (Result<Any>?, DataResponse<Any>?) -> Void

public class VideoUploader {
    /// 上传视频到服务器 (multipartFormData)
    ///
    /// - Parameters:
    ///   - videoPath: Asset URL
    ///   - server: 服务器地址（包含 baseURL）
    ///   - header: 请求 Header
    ///   - parameter: value 为文件，key 为 parameter
    ///   - method: 请求方法
    ///   - callback: Result：请求是否成功, DataResponse: 请求返回的 response
    static public func uploadVideo(videoPath: URL,
                                   toServer server: String,
                                   header: HTTPHeaders? = nil,
                                   parameter: String = "any",
                                   method: HTTPMethod = .post,
                                   _ callback: @escaping VideoUploadCallback) {
        var result: Result<Any>?
        var dataResponses: DataResponse<Any>?
        let group = DispatchGroup()
        group.enter()
        // 将视频转换成 MP4 格式
        let avAsset: AVURLAsset = AVURLAsset(url: videoPath, options: nil)
        let outputPath = NSHomeDirectory() + "/Documents/\(Date().timeIntervalSince1970).mp4"
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        if compatiblePresets.contains(AVAssetExportPresetLowQuality) {
            let exportSession: AVAssetExportSession = AVAssetExportSession.init(asset: avAsset, presetName: AVAssetExportPresetMediumQuality)!
            let existBool = FileManager.default.fileExists(atPath: outputPath)
            if existBool {
            }
            exportSession.outputURL = URL.init(fileURLWithPath: outputPath)
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .failed:
                    print("失败...\(String(describing: exportSession.error?.localizedDescription))")
                    result = .failure(exportSession.error ?? AFError.MultipartEncodingFailureReason.self as! Error)
                    group.leave()
                    break
                case .cancelled:
                    print("取消")
                    result = .failure(exportSession.error ?? AFError.MultipartEncodingFailureReason.self as! Error)
                    group.leave()
                    break
                case .completed:
                    print("转码成功")
                    let mp4Path = URL.init(fileURLWithPath: outputPath)
                    // 以表单形式上传
                    Alamofire.upload(
                        multipartFormData: { multipartFormData in
                            multipartFormData.append(mp4Path, withName: parameter, fileName: "any.mp4", mimeType: "video/mp4")
                    }, to: server,
                      method: method,
                      headers: header,
                      encodingCompletion: { encodingResult in
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
                        case .failure(let encodingError):
                            result = .failure(encodingError)
                            group.leave()
                        }
                    })
                    break
                default:
                    group.leave()
                    break
                }
            })
        }
        group.notify(queue: DispatchQueue.main) {
            callback(result, dataResponses)
        }
    }
}
