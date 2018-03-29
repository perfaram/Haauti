//
//  JodelAPI.swift
//  fronzel
//
//  Created by Perceval FARAMAZ on 26/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

extension String {
    func encodeURIComponent() -> String? {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-_.!~*'()")//("+&")
        //CharacterSet.urlQueryAllowed
        return self.addingPercentEncoding(withAllowedCharacters: characterSet)
    }
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        return hmacData.hexString!
    }
}

class JodelAPISettings {
    
    public static let version = "4.79.1"
    public static let apiVersion = "0.2"
    public static let apiServer = "https://api.go-tellm.com/api"
    
    public static let clientId = "81e8a76e-1e02-4d17-9ba0-8a7020261b26" // Android client id
    
    public static var clientType = "android_" + version // Client type for signed requests
    
    public static let secretKey = "HtJoqSysGFQXgFqYZRgwbpcFVAzLFSioVKTCwMcL" // Key for signed requests
    
    public static var postColors = ["06A3CB", "DD5F5F", "FFBA00", "FF9908", "8ABDB0", "9EC41C"] // Colors for posts, the server prevents other colors
}
