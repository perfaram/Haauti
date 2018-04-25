//
//  Document.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 21/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import CoreLocation
import Promise
import SwiftyJSON
import MapKit

public enum AwaitError : Error {
    case Timeout
    case NilError
    case NilValue
}
func await<T>(_ promise: Promise<T>) throws -> T {
    while (promise.isPending == true) {
        sleep(1)
    }
    if (promise.isRejected) {
        throw promise.error ?? AwaitError.NilError
    } else {
        guard let val = promise.value else { throw AwaitError.NilValue }
        return val
    }
}/*
func await<T>(_ closure: @autoclosure () -> Promise<T>) throws -> T {
    let promise = closure()
    while (promise.isPending == true) {
        sleep(1)
    }
    if (promise.isRejected) {
        throw promise.error ?? AwaitError.NilError
    } else {
        guard let val = promise.value else { throw AwaitError.NilValue }
        return val
    }
}*/

class JodelAccount: NSDocument {

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
        windowController.contentViewController?.representedObject = self
    }
    
    public func city(atLocation: CLLocationCoordinate2D) -> Promise<String> {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: atLocation.latitude, longitude: atLocation.longitude)
        
        let geoPromise = Promise<CLPlacemark>(work: { fulfill, reject in
            geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                // Place details
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]
                fulfill(placeMark)
            })
        })
        
        return geoPromise.then({ (mark) -> String in
            if let city = mark.locality {
                self.city = city
                return city
            }
            // Country
            /*if let country = placeMark.addressDictionary!["Country"] as? NSString {
             print(country)
             }*/
            throw JodelError.InternalError(.UnGeocodableCity)
        }).always {
            self.promisedCity = nil
            //autosave
        }
    }
    
    public init(type typeName: String) throws {
        super.init()
        
        let location = CLLocationCoordinate2D(latitude: 46.520612, longitude: 6.566654)
        let authBag = AuthBag(access_token: "36583936-4a02ef40-8327a846-0308-4606-8399-37e3938406ff",
                              expiration_date: 1521741383,
                              refresh_token: "dd615ccf-0cd9-45ef-8645-06a3f2dd64ba",
                              distinct_id: "5a26fa3ae1cb3e00103bccb2")
        let uid = "c47230706821eefa529e83582bbb0feff8c62a5e54d33cf7364f27f3263c5255"
        
        self.authenticationBag = authBag
        self.device_uid = uid
        self.country = "CH"
        self.city = "Ecublens"
        self.location = location
        return
        
        let chars : [String] = Array("abcdef0123456789").map { (char) -> String in
            return String(char)
        }
        self.device_uid = Array<Int>(0..<64)
            .map { (idx: Int) -> String in
                return chars.randomItem()!
            }
            .joined(separator: "")
        
        let locManager = CLLocationManager()
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorized,
            let loc = locManager.location {
            self.location = loc.coordinate
        } else {
            self.location = CLLocationCoordinate2D(latitude: 52.52437, longitude: 13.41053) //Berlin
        }
        
        self.country = "DE"
        promisedCity = self.city(atLocation: self.location)
        _ = self.renewAllTokens()
    }
    
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        let plist = self.toCocoaDict()
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions())
        return data
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        var format = PropertyListSerialization.PropertyListFormat.binary
        let plist = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions.init(rawValue: 0), format: &format)
        
        guard let dict = plist as? Dictionary<String, Any> else { return }
        guard let lat = dict["lat"] as? Double,
            let lng = dict["lng"] as? Double,
            let aCity = dict["city"] as? String,
            let aCountry = dict["country"] as? String,
            let deviceID = dict["device_uid"] as? String,
            let auth_bag = dict["auth_bag"] as? NSDictionary
            else { return/*throw*/ }
        
        let aLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        guard let aBag = AuthBag.fromCocoaDict(auth_bag) else { return }
        
        self.location = aLocation
        self.city = aCity
        self.country = aCountry
        self.authenticationBag = aBag
        self.device_uid = deviceID
    }

    public var location: CLLocationCoordinate2D!
    @objc public dynamic var city: String?
    @objc public dynamic var country: String!
    public var authenticationBag: AuthBag? {
        didSet {
            if (self.bagRequestedPromise == nil) {
                if let url = self.fileURL, let type = self.fileType {
                    self.save(to: url, ofType: type, for: NSDocument.SaveOperationType.autosaveInPlaceOperation, completionHandler: { (err) in
                        Swift.print(err)
                    })
                }
            }
            //updating the AccountManager with new details would would call the .toCocoaDict method, which, if bagRequestedPromise is != nil, waits upon it. Was the bag var setted in a AuthBag-related promise (and thus didSet called in this context), it would cause the said promise to wait upon itself. bad.
        }
    }
    private var bagRequestedPromise: Promise<AuthBag>? = nil
    private var promisedCity : Promise<String>? = nil
    public var device_uid: String!
    
    fileprivate var delegates = [JodelFeedType : [JodelFeedDelegate]]()
    
    public func register(feedDelegate delegate: JodelFeedDelegate, forFeed type: JodelFeedType) {
        if var delegatesForType = delegates[type] {
            delegatesForType.append(delegate)
        }
        else {
            delegates[type] = [delegate]
        }
    }
    
    private func encodeAsQueryString(_ array: [String : CustomStringConvertible]?, equator: String, separator: String) -> String {
        guard let params = array else { return "" }
        
        return params.filter { (key: String, value: Any) -> Bool in
            !key.isEmpty
            }.map { (arg: (key: String, value: CustomStringConvertible)) -> String in
                let (key, value) = arg
                let stringifiedValue = value.description
                
                if let key = key.encodeURIComponent(), let value = stringifiedValue.encodeURIComponent() {
                    return key + equator + value
                }
                return ""
            }.joined(separator: separator)
    }
    
    private func computeSignature(auth accessToken: String?, method: String, url: URL, timestamp: String,
                                  params: [String : CustomStringConvertible]?, jsonPayload payload: String?) -> String {
        guard let host = url.host else { return "" }
        let accessToken = accessToken ?? ""
        let payload = payload ?? ""
        
        var path = url.path
        if (!path.starts(with: "/")) {
            path = "/" + path;
        }
        
        let queryString = encodeAsQueryString(params, equator: "%", separator: "%")
        
        let raw = [method, host, "443", path + "/", accessToken, timestamp, queryString, payload].joined(separator: "%")
        
        return raw.hmac(algorithm: .SHA1, key: JodelAPISettings.secretKey)
    }
    
    func makeJodelURLRequest(_ method: HTTPMethod,
                             _ endpoint: String,
                             params: [String : CustomStringConvertible]? = nil,
                             payload: [String : CustomStringConvertible]? = nil,
                             authenticated: Bool = true)
        throws -> URLRequest
    {
        let methodEnumValue = method
        let method = method.rawValue.uppercased()
        var headers : [String: String] = [String: String]()
        let timestamp = Date().iso8601
        
        let jsonObj = JSON(payload)
        let payloadData = (payload != nil) ? try jsonObj.rawData(options: .init(rawValue: 0)) : nil
        let payloadString = jsonObj.rawString(options: .init(rawValue: 0))//String(data: payloadData, encoding: String.Encoding.utf8) ?? ""
        
        
        var endpoint = JodelAPISettings.apiServer + endpoint
        if let parameters = params {
            let queryString = encodeAsQueryString(parameters, equator: "=", separator: "&")
            endpoint += "?" + queryString
        }
        
        guard let endpointURL = URL(string: endpoint) else {
            throw JodelError.InternalError(.UnparseableEndpointURL)
        }
        
        /*guard let endpointURL = URL(string: "https://api.go-tellm.com/api/v3/posts/location/combo?channels=true&home=false&lat=46.52&lng=6.5&skipHometown=false&stickies=true") else {
         throw JodelError.InternalError(.UnparseableEndpointURL)
         }*/
        
        var signature = ""
        if authenticated {
            guard let bag = self.authenticationBag else {
                throw JodelError.InternalError(.UnexpectedEmptyAuthenticationBag)
            }
            
            signature = computeSignature(auth: bag.access_token,
                                         method: method,
                                         url: endpointURL,
                                         timestamp: timestamp,
                                         params: params,
                                         jsonPayload: payloadString)
            headers["Authorization"] = "Bearer " + bag.access_token
        }
        else {
            signature = computeSignature(auth: nil, method: method, url: endpointURL, timestamp: timestamp, params: params, jsonPayload: payloadString ?? "")
        }
        //477
        
        headers["X-Authorization"] = "HMAC " + signature
        headers["X-Client-Type"] = "android_" + JodelAPISettings.version
        headers["X-Timestamp"] = timestamp
        headers["X-Api-Version"] = JodelAPISettings.apiVersion
        headers["Accept-Encoding"] = "gzip"
        headers["Content-Type"] = "application/json; charset=UTF-8"
        
        /*var urlComponents = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)!
         urlComponents.queryItems = [
         URLQueryItem(name: "q", value: String(51.500833)+","+String(-0.141944)),
         URLQueryItem(name: "z", value: String(6))
         ]
         urlComponents.url*/
        
        var rq = URLRequest(url: endpointURL)
        rq.httpMethod = method
        rq.httpBody = payloadData
        
        for (field, value) in headers {
            rq.addValue(value, forHTTPHeaderField: field)
        }
        
        return rq
    }
    
    func jodelRequest(_ method: HTTPMethod,
                      _ endpoint: String,
                      params: [String : CustomStringConvertible]? = nil,
                      payload: [String : CustomStringConvertible]? = nil,
                      authenticated: Bool = true)
        -> Promise<JSON>
    {
        if authenticated {
            if self.authenticationBag == nil {
                return self.renewAllTokens().then({ (_) -> Promise<JSON> in
                    return self.jodelRequest(method,
                                             endpoint,
                                             params: params,
                                             payload: payload,
                                             authenticated: authenticated)
                })
            }
        }
        
        var rq : URLRequest
        
        do {
            rq = try makeJodelURLRequest(method,
                                         endpoint,
                                         params: params,
                                         payload: payload,
                                         authenticated: authenticated)
        } catch {
            return Promise(error: error)
        }
        
        let urlPromise = Promise<(Data, HTTPURLResponse)>(work: { fulfill, reject in
            URLSession.shared.dataTask(with: rq, completionHandler: { data, response, error in
                Swift.print(error)
                Swift.print(data)
                Swift.print(response)
                if let error = error {
                    reject(error)
                } else if let data = data, let response = response {
                    guard let response = response as? HTTPURLResponse else {
                        return reject(JodelError.InternalError(.UnexpectedResponseType))
                    }
                    
                    fulfill((data, response))
                } else {
                    fatalError("Something has gone horribly wrong.")
                }
            }).resume()
        })
        
        return urlPromise.then({ (data, response) -> Promise<JSON> in
            let payloadString = String(data: data, encoding: String.Encoding.utf8) ?? ""
            
            switch response.statusCode {
            case 401:
                if ((rq.url?.absoluteString ?? "").contains("/v2/users/refreshToken")) {
                    throw JodelError.APIError(.Double401)
                }
                return self.refreshAccessToken().then({ (_) -> Promise<JSON> in
                    return self.jodelRequest(method,
                                             endpoint,
                                             params: params,
                                             payload: payload,
                                             authenticated: authenticated)
                })
                break;
            case 200..<300:
                do {
                    if payloadString == "" {
                        return Promise(value: JSON.null)
                    }
                    let json = try JSON.init(data: data)
                    return Promise(value: json)
                } catch {
                    return Promise(error: error)
                }
            default:
                return Promise(error: JodelError.APIError(.UnexpectedStatusCode(code: response.statusCode)))
                break;
            }
        })
    }
    
    private func renewAllTokens(location: CLLocationCoordinate2D, city: String, country: String) -> Promise<AuthBag> {
        let data : [String: CustomStringConvertible] = [
            "client_id": JodelAPISettings.clientId,
            "device_uid": self.device_uid,
            "location": [
                "city": city,
                "country": country,
                "loc_accuracy": 10.56,
                "loc_coordinates": [
                    "lat": location.latitude,
                    "lng": location.longitude,
                ],
            ],
            ]
        
        bagRequestedPromise = self.jodelRequest(.post, "/v2/users/", params: nil, payload: data, authenticated: false)
            .then { (json) -> Promise<AuthBag> in
                guard let access_token = json["access_token"].string,
                    let expiration_date = json["expiration_date"].int,
                    let refresh_token = json["refresh_token"].string,
                    let distinct_id = json["distinct_id"].string,
                    access_token != "",
                    expiration_date != 0,
                    refresh_token != "",
                    distinct_id != ""
                    else { //todo better value checking
                        return Promise(error: JodelError.APIError(.MalformedResponse))
                }
                
                let bag = AuthBag(access_token: access_token,
                                  expiration_date: expiration_date,
                                  refresh_token: refresh_token,
                                  distinct_id: distinct_id)
                self.authenticationBag = bag
                return Promise(value: bag)
            }.always {
                self.bagRequestedPromise = nil
        }
        return bagRequestedPromise!
    }
    
    func renewAllTokens() -> Promise<AuthBag> {
        let cityPromise : Promise<String>
        if let city = self.city {
            cityPromise = Promise.init(value: city)
        } else if let promisedCity = self.promisedCity {
            cityPromise = promisedCity
        } else {
            cityPromise = self.city(atLocation: self.location)
        }
        
        return Promises.all([cityPromise]).then({ values in
            let city = values[0]
            return self.renewAllTokens(location: self.location, city: city, country: self.country)
        })
    }
    
    func refreshAccessToken() -> Promise<AuthBag> {
        precondition(self.authenticationBag != nil)
        
        let disID = String(self.authenticationBag?.distinct_id ?? "")
        let rTok = String(self.authenticationBag?.refresh_token ?? "")
        
        let data : [String: CustomStringConvertible] = [
            "current_client_id": JodelAPISettings.clientId,
            "distinct_id": disID,
            "refresh_token": rTok
        ]
        
        bagRequestedPromise = self.jodelRequest(.post, "/v2/users/refreshToken", params: nil, payload: data, authenticated: false)
            .then({ (json) -> Promise<AuthBag> in
                guard let access_token = json["access_token"].string,
                    let expiration_date = json["expiration_date"].int,
                    access_token != "",
                    expiration_date != 0
                    else {
                        return Promise(error: JodelError.APIError(.MalformedResponse))
                }
                
                guard var bag = self.authenticationBag else {
                    return Promise(error: JodelError.InternalError(.UnexpectedEmptyAuthenticationBag))
                }
                
                bag.access_token = access_token
                bag.expiration_date = expiration_date
                
                self.authenticationBag = bag
                return Promise<AuthBag>(value: bag)
            }).recover({ (error) -> Promise<AuthBag> in
                if let error = error as? JodelError,
                    case let JodelError.APIError(apitype) = error,
                    case .Double401 = apitype {
                    return self.renewAllTokens()
                }
                throw error
            }).always {
                self.bagRequestedPromise = nil
                //autosave
        }
        
        return bagRequestedPromise!
    }
    
    convenience init?(location: CLLocationCoordinate2D, city: String, country: String, authenticationBag aBag: AuthBag, deviceID: String?, refreshing: Bool) {
        self.init()
        
        self.location = location
        self.city = city
        self.authenticationBag = aBag
        self.country = country
        self.device_uid = deviceID
    }
    
    func toCocoaDict() -> NSDictionary {
        var maybeBag : AuthBag? = authenticationBag
        
        if let bagPromise = bagRequestedPromise {
            maybeBag = bagPromise.value
        }
        guard let aBag = maybeBag else { return NSDictionary() }
        
        var maybeCity : String? = city
        
        if let cityPromise = promisedCity {
            maybeCity = cityPromise.value
        }
        guard let city = maybeCity else { return NSDictionary() }
        
        let dict = NSMutableDictionary.init()
        dict["lat"] = location.latitude as NSNumber
        dict["lng"] = location.longitude as NSNumber
        dict["city"] = city  as NSString
        dict["country"] = country as NSString
        dict["device_uid"] = device_uid as NSString
        dict["auth_bag"] = aBag.toCocoaDict()
        return dict
    }
    
    /*class func fromCocoaDict(_ dict: NSDictionary?) -> JodelAccount? {
        guard let dict = dict as? Dictionary<String, Any> else { return nil }
        //guard let dict = dict else { return nil }
        guard let lat = dict["lat"] as? Double,
            let lng = dict["lng"] as? Double,
            let city = dict["city"] as? String,
            let country = dict["country"] as? String,
            let device_uid = dict["device_uid"] as? String,
            let auth_bag = dict["auth_bag"] as? NSDictionary
            else { return nil }
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        guard let aBag = AuthBag.fromCocoaDict(auth_bag) else { return nil }
        return JodelAccount(location: location, city: city, country: country, authenticationBag: aBag, deviceID: device_uid, refreshing: false)
    }*/
    
    /*func parseFeed(_ type: JodelFeedType, data: JSON) -> [AJodel] {
     guard let array = data.array else { continue }
     }
     
     func parseCombo(json: JSON) -> [JodelFeedType: [AJodel]] {
     var result = [JodelFeedType: [AJodel]]()
     
     for (key, subJson):(String, JSON) in json {
     var feedType : JodelFeedType = {
     switch key {
     case "stickies": return JodelFeedType.stickies
     case "recent": return JodelFeedType.recent(mine: false, hashtag: <#T##String?#>, channel: <#T##String?#>)
     }
     }()
     
     
     result[feedType] = parseFeed(feedType, data: subJson)
     }
     
     for jodelDict in json["stickies"].array ?? [] {
     let jodel = Init(AJodel()) {
     $0.postId = (jodelDict["stickypost_id"].string) ?? ""
     
     $0.message = (jodelDict["message"].string) ?? "[NO MESSAGE]"
     
     let colorHex = (jodelDict["color"].string) ?? "DDDDDD"
     $0.color = NSColor.init(hex: colorHex)
     $0.location = (jodelDict["location_name"].string) ?? "[NOWHERE]"
     
     if let buttons = (jodelDict["buttons"].array) {
     $0.buttons = [String]()
     for button in buttons {
     if let buttonDict = button.dictionary,
     let buttonStringJSON = buttonDict["title"],
     let buttonString = buttonStringJSON.string {
     $0.buttons?.append(buttonString)
     }
     }
     }
     
     $0.isSticky = true
     }
     jodelsInFeed.append(jodel)
     }
     
     for jodelDict in json["recent"].array ?? [] {
     let jodel = Init(AJodel()) {
     $0.fromHome = (jodelDict["from_home"].bool) ?? false
     $0.childCount = (jodelDict["child_count"].int) ?? -1
     $0.message = (jodelDict["message"].string) ?? "[NO MESSAGE]"
     
     let colorHex = (jodelDict["color"].string) ?? "DDDDDD"
     $0.color = NSColor.init(hex: colorHex)
     $0.score = (jodelDict["vote_count"].int) ?? -1
     
     if let location = (jodelDict["location"].dictionary) {
     $0.location = location["name"]?.string ?? "[NOWHERE]"
     }
     
     $0.distance = (jodelDict["distance"].int) ?? -1
     $0.userHandle = (jodelDict["user_handle"].string) ?? "oj"
     
     let timeStr = (jodelDict["updated_at"].string) ?? Date().iso8601
     if let jodelDate = timeStr.dateFromISO8601 {
     $0.timeStamp = jodelDate
     }
     
     $0.ojReplied = (jodelDict["oj_replied"].bool) ?? false
     $0.shareCount = (jodelDict["share_count"].int) ?? -1
     $0.pinCount = (jodelDict["pin_count"].int) ?? -1
     }
     jodelsInFeed.append(jodel)
     }
     }*/
    
    func getPostsBis()
        -> Promise<[AJodel]>
    {
        let queryparams : [String: CustomStringConvertible] = [
            "channels": true, //display Jodel posted in followed channels along w/ main feed
            "home": false, //display Jodel @Bled/Home
            "lat": self.location.latitude, //current pos, no matter whether @Home or not
            "lng": self.location.longitude, //same
            "skipHometown": false, //ignore hometown posts
            "stickies": true //also get da sticky posts
        ]
        //https://api.go-tellm.com/api/v3/posts/location/combo?channels=true&home=false&lat=46.52&lng=6.5&skipHometown=false&stickies=true
        
        let path = "/v3/posts/location/combo"
        
        return self.jodelRequest(.get, path, params: queryparams, payload: nil, authenticated: true)
            .then({ (json) -> Promise<[AJodel]> in
                Swift.print(json)
                
                var jodelsInFeed = [AJodel]()
                
                for jodelDict in json["stickies"].array ?? [] {
                    let jodel = Init(AJodel()) {
                        $0.postId = (jodelDict["stickypost_id"].string) ?? ""
                        
                        $0.message = (jodelDict["message"].string) ?? "[NO MESSAGE]"
                        
                        let colorHex = (jodelDict["color"].string) ?? "DDDDDD"
                        $0.color = NSColor.init(hex: colorHex)
                        $0.location = (jodelDict["location_name"].string) ?? "[NOWHERE]"
                        
                        if let buttons = (jodelDict["buttons"].array) {
                            $0.buttons = [String]()
                            for button in buttons {
                                if let buttonDict = button.dictionary,
                                    let buttonStringJSON = buttonDict["title"],
                                    let buttonString = buttonStringJSON.string {
                                    $0.buttons?.append(buttonString)
                                }
                            }
                        }
                        
                        $0.isSticky = true
                    }
                    jodelsInFeed.append(jodel)
                }
                
                for jodelDict in json["recent"].array ?? [] {
                    let jodel = Init(AJodel()) {
                        $0.fromHome = (jodelDict["from_home"].bool) ?? false
                        $0.childCount = (jodelDict["child_count"].int) ?? -1
                        $0.message = (jodelDict["message"].string) ?? "[NO MESSAGE]"
                        
                        let colorHex = (jodelDict["color"].string) ?? "DDDDDD"
                        $0.color = NSColor.init(hex: colorHex)
                        $0.score = (jodelDict["vote_count"].int) ?? -1
                        
                        if let location = (jodelDict["location"].dictionary) {
                            $0.location = location["name"]?.string ?? "[NOWHERE]"
                        }
                        
                        $0.distance = (jodelDict["distance"].int) ?? -1
                        $0.userHandle = (jodelDict["user_handle"].string) ?? "oj"
                        
                        let timeStr = (jodelDict["updated_at"].string) ?? Date().iso8601
                        if let jodelDate = timeStr.dateFromISO8601 {
                            $0.timeStamp = jodelDate
                        }
                        
                        $0.ojReplied = (jodelDict["oj_replied"].bool) ?? false
                        $0.shareCount = (jodelDict["share_count"].int) ?? -1
                        $0.pinCount = (jodelDict["pin_count"].int) ?? -1
                    }
                    jodelsInFeed.append(jodel)
                }
                
                return Promise(value: jodelsInFeed)
            })
    }
    
    func get_posts(_ type: String,
                   skip: Int = 0,
                   limit: Int = 60,
                   after: String? = nil,
                   mine: Bool = false,
                   hashtag: String? = nil,
                   channel: String? = nil,
                   pictures: Bool = false)
        -> Promise<[AJodel]>
    {
        //return getPostsBis()
        let category : String = {
            if mine {
                return "mine"
            } else if hashtag != nil {
                return "hashtag"
            } else if channel != nil {
                return "channel"
            } else {
                return "location"
            }
        }()
        
        let api_version = (hashtag != nil || channel != nil || pictures) ? "v3" : "v2"
        let pictures_posts = (pictures) ? "pictures" : "posts"
        
        let path = "/" + ([api_version, pictures_posts, category, type].joined(separator: "/"))
        
        let bodyParams : [String: CustomStringConvertible] = [
            "lat": self.location.latitude,
            "lng": self.location.longitude,
            "skip": skip,
            "limit": limit,
            "hashtag": hashtag ?? "",
            "channel": channel ?? "",
            "after": after ?? ""
        ]
        
        return self.jodelRequest(.get, path, params: bodyParams, payload: nil, authenticated: true)
            .then({ (json) -> Promise<[AJodel]> in
                Swift.print(json)
                
                var jodelsInFeed = [AJodel]()
                
                for jodelDict in json["posts"].array ?? [] {
                    let jodel = Init(AJodel()) {
                        $0.fromHome = (jodelDict["from_home"].bool) ?? false
                        $0.childCount = (jodelDict["child_count"].int) ?? -1
                        $0.message = (jodelDict["message"].string) ?? "[NO MESSAGE]"
                        
                        let colorHex = (jodelDict["color"].string) ?? "DDDDDD"
                        $0.color = NSColor.init(hex: colorHex)
                        $0.score = (jodelDict["vote_count"].int) ?? -1
                        
                        if let location = (jodelDict["location"].dictionary) {
                            $0.location = location["name"]?.string ?? "[NOWHERE]"
                        }
                        
                        $0.distance = (jodelDict["distance"].int) ?? -1
                        $0.userHandle = (jodelDict["user_handle"].string) ?? "oj"
                        
                        let timeStr = (jodelDict["updated_at"].string) ?? Date().iso8601
                        if let jodelDate = timeStr.dateFromISO8601 {
                            $0.timeStamp = jodelDate
                        }
                        
                        $0.ojReplied = (jodelDict["oj_replied"].bool) ?? false
                        $0.shareCount = (jodelDict["share_count"].int) ?? -1
                        $0.pinCount = (jodelDict["pin_count"].int) ?? -1
                    }
                    jodelsInFeed.append(jodel)
                }
                
                return Promise(value: jodelsInFeed)
                
            })
        
        /*
         
         url = "/{api_version}/{pictures_posts}/{category}/{post_types}".format(**url_params)
         return self._send_request("GET", url, params=params, **kwargs)
         */
    }
    
    func dismissSticky(_ post: AJodel) -> Promise<Bool> {
        let path = "/v3/stickyposts/" + post.postId + "/up"
        return self.jodelRequest(.put, path, params: nil, payload: nil, authenticated: true)
            .then { (json) -> Promise<Bool> in
                Swift.print(json)
                return Promise(value: true)//todo real return val
            }.recover({ (error) -> Promise<Bool> in
                if let error = error as? SwiftyJSONError {
                    if (error == SwiftyJSONError.invalidJSON) {
                        return Promise(value: true)
                    }
                }
                return Promise(error: error)
            })
    }
    
    func updateJodelList(for type: JodelFeedType) {
        let typeString : String = {
            switch type {
            case .recent(let mine):
                return ""
            case .popular(let mine):
                return "popular"
            case .discussed(let mine):
                return "discussed"
            case .pinned:
                return "get_my_pinned_posts"
            default:
                return ""
            }
        }()
        
        get_posts(typeString).then { (list) in
            if let delegates = self.delegates[type] {
                for dlg in delegates {
                    dlg.feedUpdated(list)
                }
            }
        }.catch { (error) in
            Swift.print(error)
            let jdlErr : JodelError
            if let error = error as? JodelError {
                jdlErr = error
            }
            else {
                jdlErr = JodelError.OtherError(error)
            }
            
            if let delegates = self.delegates[type] {
                for dlg in delegates {
                    dlg.errorOccurred(jdlErr)
                }
            }
        }
        
        /*let rawResponse = PythonList(wrappedPythonAccount.call(method))
         
         guard let recentPostsResponse = rawResponse.typedBridgeFromPython()
         else { return [] }
         
         guard recentPostsResponse[0]! as! Int == 200 else { return [] /*return da error and display it in empty view*/ }
         let recentPosts = ((recentPostsResponse[1]) as? [AnyHashable : Any?])?["posts"] as! [Any?]?
         
         var jodelsInFeed = [AJodel]()
         
         for (jodelArray) in recentPosts ?? [] {
         if let jodelArray = jodelArray as? [String : Any?] {
         let jodelArray = jodelArray.mapValues { //todo recursive map
         $0 ?? "None"
         }
         //print(jodelArray)
         
         let jodel = Init(AJodel()) {
         $0.fromHome = (jodelArray["from_home"] as? Bool) ?? false
         $0.childCount = (jodelArray["child_count"] as? Int) ?? -1
         $0.message = (jodelArray["message"] as? String) ?? "[NO MESSAGE]"
         
         let colorHex = (jodelArray["color"] as? String) ?? "DDDDDD"
         $0.color = NSColor.init(hex: colorHex)
         $0.score = (jodelArray["vote_count"] as? Int) ?? -1
         
         if let location = (jodelArray["location"] as? [String : Any?]) {
         let location = location.mapValues { //todo recursive map
         $0 ?? "None"
         }
         $0.location = (location["name"] as? String) ?? "Nulle part"
         }
         
         $0.distance = (jodelArray["distance"] as? Int) ?? -1
         $0.userHandle = (jodelArray["user_handle"] as? String) ?? "oj"
         
         let timeStr = (jodelArray["updated_at"] as? String) ?? Date().iso8601
         if let jodelDate = timeStr.dateFromISO8601 {
         $0.timeStamp = jodelDate
         }
         
         $0.ojReplied = (jodelArray["oj_replied"] as? Bool) ?? false
         $0.shareCount = (jodelArray["share_count"] as? Int) ?? -1
         $0.pinCount = (jodelArray["pin_count"] as? Int) ?? -1
         }
         jodelsInFeed.append(jodel)
         }
         }
         
         return jodelsInFeed*/
    }
    
    /*convenience init(mockJodelsCount: Int) {
     self.init()
     
     jodelsInFeed = [AJodel]()
     
     let fakery = Faker.init(locale: "fr_FR")
     
     for _ in 0..<mockJodelsCount {
     let jodel = Init(AJodel()) {
     $0.fromHome = true
     $0.childCount = 17
     $0.message = Lorem.jodel()
     
     let colorHex = ["9EC41C", "FF9908", "DD5F5F", "8ABDB0", "06A3CB", "FFBA00"].random
     $0.color = NSColor.init(hex: colorHex)
     $0.score = fakery.number.randomInt(min: -5, max: 120)
     $0.childCount = fakery.number.randomInt(min: 0, max: 30)
     
     $0.location = ["Ouest lausannois", "Morges", "Oron-Lavaux", "Montreux"].random
     $0.fromHome = fakery.number.randomBool()
     $0.distance = fakery.number.randomInt(min: 0, max: 20)
     
     let timeStr = Date().generateRandomDate(daysBack: 1).iso8601
     if let jodelDate = timeStr.dateFromISO8601 {
     $0.timeStamp = jodelDate
     }
     
     }
     jodelsInFeed.append(jodel)
     }
     
     jodelsInFeed = jodelsInFeed.sorted(by: { $0.timeStamp.compare($1.timeStamp) == ComparisonResult.orderedDescending })
     }*/
}

