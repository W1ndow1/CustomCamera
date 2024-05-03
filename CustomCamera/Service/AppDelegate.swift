//
//  AppDelegate.swift
//  CustomCamera
//
//  Created by window1 on 5/3/24.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    @Published var shouldRotate: Bool = false
    
    //화면 고정하기
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let orientationMask: [UIInterfaceOrientationMask] = shouldRotate ? [.all] : [.portrait]
        return UIInterfaceOrientationMask(orientationMask)
    }
}
