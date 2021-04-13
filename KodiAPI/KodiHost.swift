//
//  KodiHost.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/11/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import Foundation

@objc public class KodiHost: NSObject, Codable {
    public var name: String
    public var user: String = ""
    public var pass: String = ""
    public var serverIp: String
    public var serverPort: Int = 8080
    
    public init(fromDict dict: [String:Any]) {
        name = dict["serverDescription"] as! String
        user = (dict["serverUser"] as? String) ?? ""
        pass = (dict["serverPass"] as? String) ?? ""
        serverIp = dict["serverIP"] as! String
        
        if let port = dict["serverPort"] as? String {
            serverPort = Int(port) ?? 8080
        }
    }
    
    @objc public static func decode(fromJson data: Data) throws -> KodiHost {
        return try JSONDecoder().decode(KodiHost.self, from: data)
    }
}
