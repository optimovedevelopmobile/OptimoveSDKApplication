import UIKit
import Firebase
import OptimoveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OptimoveStateDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let tenantInfo = OptimoveTenantInfo(token: "586b34667efff2d96c1d4062e5652835",
                                            id: 500,
                                            version: "1.0.0",
                                            apiKey: "AIzaSyAbe-FyTij_t_P2lX8RycHKbMqS3Fmm-kA",
                                            hasFirebase: false)
        Optimove.sharedInstance.configure(info: tenantInfo)
        Optimove.sharedInstance.register(stateDelegate: self)
        return true
    }
    
    var id: Int {
        return 136
    }
    
    func didBecomeActive() {
        print("Optimove SDK is now ACTIVE!!!")
    }
    
    func didStartLoading() {
        print("Optimove SDK is now LOADING!!!")
    }
    
    func didBecomeInvalid(withErrors errors: [OptimoveError]) {
        print("Optimove SDK is now FAILED!!!\n with errors: \(errors)")
    }
}

