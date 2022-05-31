//
//  MSGHubMessaging.swift
//  
//
//  Created by Pavel Pavlov on 24.01.22.
//
import Foundation
import CoreTelephony
import UIKit
import Firebase
import SystemConfiguration
import UserNotifications
import Alamofire
import NotificationCenter
import SafariServices
import MSGHubInternal
import DeviceKit

open class MSGHubMessaging: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    public static let INSTANCE = MSGHubMessaging()
    private let msgHubInternal = MSGHubInternalData.INSANCE
    var bundleId: String = ""
    public weak var redirectProtocol: RedirectProtocol?
    
    public override init() {
    }
    
    public func initialize(bundleID: String, application: UIApplication) {
        
        self.bundleId = bundleID
        setBundleId(bundle: bundleID)
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        let category = UNNotificationCategory(identifier: msgHubInternal.msghub_notif_id, actions: [], intentIdentifiers: [], options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        application.registerForRemoteNotifications()
        
        subscribe(toTopic: getBundleId() + msgHubInternal.IOS_ID)
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        setApnsToken(token: deviceToken)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        if let msgID = userInfo[msgHubInternal.json_key_message_id] {
            sendNotidficationDLR(messageID: msgID as? String ?? "", action: 0)
        }
        
        print(userInfo)
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let msgID = userInfo[msgHubInternal.json_key_message_id] {
            sendNotidficationDLR(messageID: msgID as? String ?? "", action: 1)
        }
        
        if let redirectUrl = userInfo[msgHubInternal.redirect_url] as? String {
            
            if let encodedUrl = redirectUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                
                guard let url = URL(string: encodedUrl) else {
                    return
                }
                
                if shouldOpenUrlExternal() {
                    UIApplication.shared.open(url)
                } else {
                    self.redirectProtocol?.onExternalNotificationUrl(url: url)
                }
                
            }
            
        }
        
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // notification dissmissed (not tested properly)
        }
        
        print(response)
        
        completionHandler()
    }
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        let dataDict:[String: String] = [msgHubInternal.token: fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        
        subscribe(toTopic: getDeviceUUID())
    }
    
    public func subscribe(toTopic: String) {
        if (toTopic.isEmpty) {return}
        Messaging.messaging().subscribe(toTopic: toTopic) { error in
            self.registerForRemoteNotifications()
        }
    }
    
    public func unsubscribe(fromTopic: String) {
        if (fromTopic.isEmpty) {return}
        Messaging.messaging().unsubscribe(fromTopic: fromTopic) { error in
            self.registerForRemoteNotifications()
        }
    }
    
    private func updateFCMToken() {
        Messaging.messaging().token { token, error in
            if error != nil {
                //ignored
            } else if let token = token {
                self.putValue(key: self.msgHubInternal.fcm_token, value: token)
            }
        }
    }
    
    private func getFcmToken() -> String {
        if self.getValue(key: msgHubInternal.fcm_token) == nil {
            return ""
        }
        return self.getValue(key: msgHubInternal.fcm_token)!
    }
    
    public func setApnsToken(token: Data) {
        Messaging.messaging().apnsToken = token
        updateFCMToken()
    }
    
    public func getDeviceUUID() -> String {
        if self.getValue(key: msgHubInternal.key_uid) == nil {
            self.putValue(key: msgHubInternal.key_uid, value: getBundleId() + "_" + UUID().uuidString)
        }
        
        return self.getValue(key: msgHubInternal.key_uid)!
    }
    
    public func setDeviceUUID(uuid: String) {
        unsubscribe(fromTopic: getDeviceUUID())
        
        self.putValue(key: msgHubInternal.key_uid, value: getBundleId() + "_" + uuid)
        
        subscribe(toTopic: getBundleId() + msgHubInternal.uuid_delimiter + uuid)
    }
    
    private func setBundleId(bundle: String) {
        self.putValue(key: msgHubInternal.key_bundle_id, value: bundle)
    }
    
    private func getBundleId() -> String {
        if self.getValue(key: msgHubInternal.key_bundle_id) == nil {
            self.putValue(key: msgHubInternal.key_bundle_id, value: self.bundleId)
        }
        
        return self.getValue(key: msgHubInternal.key_bundle_id)!
    }
    
    private func registerForRemoteNotifications() {
        
        let params = [
            msgHubInternal.json_key_token: getFcmToken(),
            msgHubInternal.json_key_package: getBundleId(),
            msgHubInternal.json_key_model: Device.current.description,
            msgHubInternal.json_key_os: msgHubInternal.ios,
            msgHubInternal.json_key_vc: UIDevice.current.systemVersion
        ]
        
        AF.request(msgHubInternal.register_device_endpoing + getDeviceUUID(),
                   method: HTTPMethod.post,
                   parameters: params,
                   encoder: JSONParameterEncoder.default,
                   headers: [msgHubInternal.header_key_tera: msgHubInternal.auth_token, "Content-Type": "application/json; charset=utf-8"])
            .responseJSON { response in
                //ignored
            }
        
    }
    
    private func sendNotidficationDLR(messageID: String, action: Int) { //0 - received | 1 - opened
        
        let timestamp = String(NSDate().timeIntervalSince1970)
        
        let params = [
            msgHubInternal.json_key_status: String(action),
            msgHubInternal.json_key_ts: String(timestamp),
            msgHubInternal.json_key_message_id: messageID,
            msgHubInternal.json_key_uid: getDeviceUUID()
        ]
        
        AF.request(msgHubInternal.dlr_endpoint,
                   method: HTTPMethod.post,
                   parameters: params,
                   encoder: JSONParameterEncoder.default,
                   headers: [msgHubInternal.header_key_tera: msgHubInternal.auth_token])
            .responseJSON { response in
                //ignored
            }
    }
    
    public func setOpenUrlExternal(openExternal: Bool) {
        self.putBoolean(key: "open_external", value: openExternal)
    }
    
    private func shouldOpenUrlExternal() -> Bool {
        if self.getBoolean(key: "open_external") == nil {
            return false
        }
        return self.getBoolean(key: "open_external")!
    }
    
    private func getValue(key: String) -> String? {
        let preferences = UserDefaults.standard
        if preferences.string(forKey: key) == nil {
            return nil
        } else {
            return preferences.string(forKey: key)
        }
    }
    
    private func putValue(key: String, value: String) {
        let preferences = UserDefaults.standard
        preferences.set(value, forKey: key)
    }
    
    private func putBoolean(key: String, value: Bool?) {
        let preferences = UserDefaults.standard
        preferences.set(value, forKey: key)
    }
    
    private func getBoolean(key: String) -> Bool? {
        let preferences = UserDefaults.standard
        return preferences.bool(forKey: key) == false ? false : preferences.bool(forKey: key)
    }
    
}

public protocol RedirectProtocol : NSObjectProtocol {
    func onExternalNotificationUrl(url: URL)
}
