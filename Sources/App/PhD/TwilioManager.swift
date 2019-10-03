//
//  TwilioManager.swift
//
//  Created by Steven O'Toole on 9/4/17.
//
import Foundation
import Vapor

struct TwilioManager {
    static let shared = TwilioManager()
    private init?() {
        guard let
            sid = ProcessInfo.processInfo.environment["TWILIO_SID"]
        else { TwilioManager.log?.error("SMS FAIL: Missing SID"); return nil }
        guard let
            token = ProcessInfo.processInfo.environment["TWILIO_TOKEN"]
        else { TwilioManager.log?.error("SMS FAIL: Missing TOKEN"); return nil }
        guard let
            fromPhone = ProcessInfo.processInfo.environment["TWILIO_FROM"]
        else { TwilioManager.log?.error("SMS FAIL: Missing FROM"); return nil }
        print("******* twilio sid", sid)
        self.sid = sid
        self.token = token
        self.fromPhone = fromPhone
    }
    public static var log: LogProtocol?

    private let urlPrefix = "https://api.twilio.com/2010-04-01/Accounts/"
    private let sid: String
    private let token: String
    private let fromPhone: String 
    private let toPrefixDefault = "+1"

    func sendSMSFromClient(_ client: ClientFactoryProtocol, toPhone: String, message: String) throws {
        try sendSMSFromClient(client, toPrefix: toPrefixDefault, toPhone: toPhone, message: message)
    }

    // https://www.twilio.com/docs/api/messaging
    func sendSMSFromClient(_ client: ClientFactoryProtocol, toPrefix: String, toPhone: String, message: String) throws {
        guard let authData = "\(sid):\(token)".data(using: .utf8)
        else { throw Abort(.internalServerError, reason: "SMS FAIL Authdata") }
        let base64EncodedCredential = authData.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential)"

        let urlString = "\(urlPrefix)\(sid)/Messages.json"
        let req = Request(method: .post, uri: urlString, headers: ["Authorization": authString])
        req.formURLEncoded = try Node(node: [
            "To": "\(toPrefix)\(toPhone)", "From": fromPhone, "Body": message
            ])
        let response = try client.respond(to: req)
        TwilioManager.log?.error("===========================")
        TwilioManager.log?.error("response=\(response.status)\n \(response)")
    }
}

// MARK: - Debug
extension TwilioManager {
    fileprivate func logRequest(_ req: URLRequest) {
        TwilioManager.log?.error("===========================")
        TwilioManager.log?.error("\(req.httpMethod ?? "") \(req)")

        let bodyString: String
        if let data = req.httpBody {
            bodyString = String(data: data, encoding: .utf8) ?? ""
        } else {
            bodyString = ""
        }
        TwilioManager.log?.error("BODY \n \(bodyString)")
        TwilioManager.log?.error("HEADERS \n \(String(describing: req.allHTTPHeaderFields))")
    }
}
