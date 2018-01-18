import UIKit
import ZBSimplePluginManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var pluginManager: ZBSimplePluginManager?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		let resourceURL = URL(fileURLWithPath: Bundle.main.resourcePath!)
		let pluginFolder = resourceURL.appendingPathComponent("PluginScripts")
		pluginManager = ZBSimplePluginManager(pluginFolderURL: pluginFolder, defaultsNameSpace: "plugins")
		pluginManager?.loadAllPlugins()
		return true
	}
}

