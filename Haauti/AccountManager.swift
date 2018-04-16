//
//  AccountManager.swift
//  fronzel
//
//  Created by Perceval FARAMAZ on 21/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

struct AuthBag {
    var access_token: String!
    var expiration_date: Int!
    var refresh_token: String!
    var distinct_id: String!
    
    func toCocoaDict() -> NSDictionary {
        var dict = NSMutableDictionary.init()
        dict["access_token"] = access_token as NSString
        dict["expiration_date"] = expiration_date as NSNumber
        dict["refresh_token"] = refresh_token as NSString
        dict["distinct_id"] = distinct_id as NSString
        return dict
    }
    
    static func fromCocoaDict(_ dict: NSDictionary) -> AuthBag? {
        guard let dict = dict as? Dictionary<String, Any> else { return nil }
        guard let access_token = dict["access_token"] as? String,
            let expiration_date = dict["expiration_date"] as? Int,
            let refresh_token = dict["refresh_token"] as? String,
            let distinct_id = dict["distinct_id"] as? String
            else { return nil }
        
        return AuthBag(access_token: access_token, expiration_date: expiration_date, refresh_token: refresh_token, distinct_id: distinct_id)
    }
}
/*
class AccountManager {
    static let shared = AccountManager()
    
    var accounts: [String : JodelAccount] {
        get {
            if let returnValue = UserDefaults.standard.object(forKey: "accounts") as? [NSDictionary] {
                let accountArray = returnValue.map({ (dict) -> JodelAccount? in
                    return JodelAccount.fromCocoaDict(dict)
                }).filter({ (accountOptional) -> Bool in
                    return accountOptional != .none
                }).map({ (account) -> JodelAccount in
                    return account!
                })
                
                var accountDict =  [String : JodelAccount]()
                for value in accountArray {
                    accountDict[value.device_uid] = value
                }
                return accountDict
            } else {
                return [:]
            }
        }
        set {
            var accountArray = [NSDictionary]()
            
            for (_, account) in newValue {
                accountArray.append(account.toCocoaDict())
            }
            
            UserDefaults.standard.set(accountArray, forKey: "accounts")
            UserDefaults.standard.synchronize()
        }
    }
}*/
