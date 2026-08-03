// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2026 Mariia Perehozhuk
// SPDX-License-Identifier: GPL-3.0-or-later

import NextcloudKit
import Alamofire
import SwiftyJSON

class LoginFlowV2Customized {

    public static let shared: LoginFlowV2Customized = {
        let instance = LoginFlowV2Customized()
        return instance
    }()

    private let nkCommonInstance = NextcloudKit.shared.nkCommonInstance

    // clone of getLoginFlowV2Poll from NextcloudKit with token in body parameters
    func getLoginFlowV2Poll(token: String,
                            endpoint: String,
                            options: NKRequestOptions = NKRequestOptions(),
                            taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
                            completion: @escaping (_ server: String?, _ loginName: String?, _ appPassword: String?, _ responseData: AFDataResponse<Data>?, _ error: NKError) -> Void) {

        guard let url = endpoint.asUrl else {
            return options.queue.async { completion(nil, nil, nil, nil, .urlError) }
        }
        var headers: HTTPHeaders?
        if let userAgent = options.customUserAgent {
            headers = [HTTPHeader.userAgent(userAgent)]
        }

        let parameters = ["token": token]

        unauthorizedSession.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate(statusCode: 200..<300).onURLSessionTaskCreation { task in
            task.taskDescription = options.taskDescription
            taskHandler(task)
        }.responseData(queue: self.nkCommonInstance.backgroundQueue) { response in
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response, responseData: response.data)
                options.queue.async { completion(nil, nil, nil, response, error) }
            case .success(let jsonData):
                let json = JSON(jsonData)
                let server = json["server"].string
                let loginName = json["loginName"].string
                let appPassword = json["appPassword"].string

                options.queue.async { completion(server, loginName, appPassword, response, .success) }
            }
        }
    }

    // clone of unauthorizedSession from NextcloudKit without eventMonitors
    internal lazy var unauthorizedSession: Alamofire.Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        return Alamofire.Session(configuration: configuration,
                                 delegate: LoginFlowSessionDelegate(nkCommonInstance: nkCommonInstance),
                                 eventMonitors: [])
    }()
}

// clone of NextcloudKitSessionDelegate from NextcloudKit
class LoginFlowSessionDelegate: SessionDelegate, @unchecked Sendable {
    public let nkCommonInstance: NKCommon?

    public init(fileManager: FileManager = .default, nkCommonInstance: NKCommon? = nil) {
        self.nkCommonInstance = nkCommonInstance
        super.init(fileManager: fileManager)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let nkCommon = self.nkCommonInstance,
           let delegate = nkCommon.delegate {
            delegate.authenticationChallenge(session, didReceive: challenge) { authChallengeDisposition, credential in
                completionHandler(authChallengeDisposition, credential)
            }
        } else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}
