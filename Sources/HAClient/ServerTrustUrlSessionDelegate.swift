import Foundation

public class ServerTrustUrlSessionDelegate: NSObject, URLSessionDelegate {
    
    public static let urlSession: URLSession = {
        let operationQueue = OperationQueue()
        let config = URLSessionConfiguration.ephemeral
        return URLSession(configuration: config, delegate: ServerTrustUrlSessionDelegate(), delegateQueue: operationQueue)
    }()
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
