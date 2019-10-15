#if os(iOS)
import UIKit
#endif

#if os(OSX)
import AppKit
#endif

import JavaScriptCore

/// A class that represents a plug-in.
public class ZBPlugin {
	/// ID of the plug-in.
	public private(set) var ID: String
	/// Title of the plug-in.
	public private(set) var title: String
	/// What the plugin actually does.
	public private(set) var action: JSValue?
	/// Is the plugin enabled or not.
	public fileprivate(set) var enabled: Bool = false

	fileprivate init(ID: String, title: String, action: JSValue?, enabled: Bool) {
		self.ID = ID
		self.title = title
		self.action = action
		self.enabled = enabled
	}

	/// Call the action of the plugin.
	///
	/// - Parameter args: The arguments.
	/// - Returns: The results.
	public func call(args: [Any]) -> Any? {
		return self.action?.call(withArguments: args)
	}
}

// MARK: -

extension Notification.Name {
	/// A notification that is fired when a plug-in manager completes loading plug-ins.
	static let pluginManagerDidLoadPlugins = Notification.Name("pluginManagerDidLoadPlugins")
	/// A notification that is fired when a plug-in manager resets all plug-ins.
	static let pluginManagerDidResetPlugins = Notification.Name("pluginManagerDidLoadPlugins")
	/// A notification that is fired when a plug-in manager resets all settings.
	static let pluginManagerDidResetSettings = Notification.Name("pluginManagerDidResetSettings")
}

enum ZBSimplePluginManagerError: Error {
	case overrideRegisterPluginAPI

	var localizedDescription: String {
		switch self {
		case .overrideRegisterPluginAPI:
			return NSLocalizedString("You cannot replace the \"registerPlugin\" function", comment: "error message")
		}
	}
}

// MARK: -

/// ZBSimplePluginManager helps to load and manage JavaScript plug-ins.
public class ZBSimplePluginManager {
	/// All of the loaded plug-ins.
	public private(set) var plugins = [ZBPlugin]()
	/// A filtered list of enabled plug-ins.
	public var enabledPlugins: [ZBPlugin] {
		return self.plugins.filter { $0.enabled }
	}

	fileprivate var jsContext: JSContext = JSContext()
	private var pluginFolderURL: URL
	private var defaultsNamespace: String

	/// A public property that helps to store values.
	public var valueStorage:[String: Any] = [String: Any]()

	// MARK: -

	/// Create an instance by given parameters.
	///
	/// - Parameters:
	///   - pluginFolderURL: Where are the JavaScript plug-ins located at.
	///   - defaultsNamespace: A name space for setting user defaults.
	public init(pluginFolderURL: URL, defaultsNamespace: String = "plug-ins") {
		self.pluginFolderURL = pluginFolderURL
		self.defaultsNamespace = defaultsNamespace
		jsContext.name = "ZBSimplePluginManager"
		self.buildPluginRegisterationAPI()
		self.buildJavaScriptAPIs()
	}

	// MARK: - Methods related with creating JavaScript APIs.

	/// Add new JavsScript function to the manager.
	///
	/// Note: You cannot override the "registerPlugin" function.
	///
	/// - Parameters:
	///   - functionName: Name of the function.
	///   - block: Implementation of the function.
	///   - input: Input value of the function.
	/// - Throws: Errors that cuase you cannot add new functions.
	public func addJavaScriptAPI(functionName: String, blockWithArgument: @escaping (_ input: Any?) -> (Any?)) throws {
		if functionName == "registerPlugin" {
			throw ZBSimplePluginManagerError.overrideRegisterPluginAPI
		}
		let objcBlock: @convention (block) (Any?) -> (Any?) = { input in
			return blockWithArgument(input)
		}
		self.jsContext.setObject(unsafeBitCast(objcBlock, to: AnyObject.self), forKeyedSubscript: functionName as NSString)
	}

	/// Add new JavsScript function to the manager.
	///
	/// Note: You cannot override the "registerPlugin" function.
	///
	/// - Parameters:
	///   - functionName: Name of the function.
	///   - block: Implementation of the function.
	///   - arg1: The first argument.
	///   - arg2: The second argument.
	/// - Throws: Errors that cuase you cannot add new functions.
	public func addJavaScriptAPI(functionName: String, blockWithTwoArguments: @escaping (_ arg1: Any?, _ arg2: Any?) -> (Any?)) throws {
		if functionName == "registerPlugin" {
			throw ZBSimplePluginManagerError.overrideRegisterPluginAPI
		}
		let objcBlock: @convention (block) (Any?, Any?) -> (Any?) = { arg1, arg2 in
			return blockWithTwoArguments(arg1, arg2)
		}
		self.jsContext.setObject(unsafeBitCast(objcBlock, to: AnyObject.self), forKeyedSubscript: functionName as NSString)
	}

	fileprivate func buildPluginRegisterationAPI() {

		func checkIfPluginEnabledInUserDefaults(pluginID: String) -> Bool {
			let settingMap = UserDefaults.standard.dictionary(forKey: defaultsNamespace) as? [String: Bool] ?? [String: Bool]()
			return settingMap[pluginID] ?? true
		}

		let registerPlugin: @convention (block) (JSValue?) -> Bool = { pluginJSObject in
			guard let pluginJSObject = pluginJSObject,
				let pluginID = pluginJSObject.forProperty("id").toString() else {
					return false
			}
			let exitingPluginIDs = self.plugins.map {
				$0.ID
			}
			if exitingPluginIDs.contains(pluginID) {
				return false
			}
			guard let title = pluginJSObject.forProperty("title").toString() else {
				return false
			}
			let action = pluginJSObject.forProperty("action")
			let enabled = checkIfPluginEnabledInUserDefaults(pluginID: pluginID)
			let plugin = ZBPlugin(ID: pluginID, title: title, action: action, enabled: enabled)
			self.plugins.append(plugin)
			return true
		}
		self.jsContext.setObject(unsafeBitCast(registerPlugin, to: AnyObject.self), forKeyedSubscript: "registerPlugin" as NSString)
	}

	fileprivate func buildJavaScriptAPIs() {

		// MARK: log
		try? self.addJavaScriptAPI(functionName: "log") { log in
			if let log = log as? String {
				print(log)
			}
			return nil
		}

		// MARK: openURL
		try? self.addJavaScriptAPI(functionName:"openURL") { urlString in
			guard let urlString = urlString as? String,
				let url = URL(string:urlString) else {
					return nil
			}
			#if os(iOS)
			if #available(iOS 10.0, *) {
				UIApplication.shared.open(url, options: [:], completionHandler:nil)
			} else {
				UIApplication.shared.openURL(url)
			}
			#endif
			#if os(OSX)
			NSWorkspace.shared.open(url)
			#endif
			return nil
		}

		// MARK: set
		try? self.addJavaScriptAPI(functionName:"set") { key, value in
			guard let key = key as? String else {
				return nil
			}
			self.valueStorage[key] = value
			return nil
		}

		// MARK: get
		try? self.addJavaScriptAPI(functionName:"get") { key in
			guard let key = key as? String else {
				return nil
			}
			return self.valueStorage[key]
		}

	}

	// MARK: - Methods related with loading plug-ins.

	/// Load all plug-ins from the given folder path.
	public func loadAllPlugins() {
		plugins.removeAll()
		let pluginFolder = self.pluginFolderURL.path
		guard let enumerator = FileManager.default.enumerator(atPath: pluginFolder) else {
			NotificationCenter.default.post(name: .pluginManagerDidLoadPlugins, object: self)
			return
		}
		for path in enumerator {
			let fullpath = (pluginFolder as NSString).appendingPathComponent(path as! String)
			_ = self.loadJavaScript(fileURL: URL(fileURLWithPath: fullpath))
		}
		plugins.sort { $0.title < $1.title }
		NotificationCenter.default.post(name: .pluginManagerDidLoadPlugins, object: self)
	}

	/// Remove all plug-ins.
	public func resetPlugins() {
		plugins.removeAll()
		NotificationCenter.default.post(name: .pluginManagerDidResetPlugins, object: self)
	}

	/// Enable or disable a plugin.
	///
	/// - Parameters:
	///   - plugin: The plugin.
	///   - enabled: Enabled or not.
	public func toggle(plugin: ZBPlugin, enabled: Bool) {
		plugin.enabled = enabled
		var settingMap = UserDefaults.standard.dictionary(forKey: defaultsNamespace) as? [String: Bool] ?? [String: Bool]()
		settingMap[plugin.title] = enabled
		UserDefaults.standard.set(settingMap, forKey: self.defaultsNamespace)
	}

	/// Remove all of the plug-in enable/disable settings.
	public func resetSettings() {
		UserDefaults.standard.removeObject(forKey: self.defaultsNamespace)
		for plugin in self.plugins {
			plugin.enabled = true
		}
		NotificationCenter.default.post(name: .pluginManagerDidResetSettings, object: self)
	}

	// MARK: -

	/// Evaluate JavaScript code.
	///
	/// - Parameter string: The Javascript code to evaluate.
	/// - Returns: The result.
	public func loadJavaScript(string: String) -> Any? {
		return self.jsContext.evaluateScript(string)
	}

	/// Evaluate JavaScript code from a text file.
	///
	/// - Parameter fileURL: The file to evaluate.
	/// - Returns: The result.
	public func loadJavaScript(fileURL: URL) -> Any? {
		if !fileURL.isFileURL {
			return nil
		}
		guard let text = try? String(contentsOf: fileURL) else {
			return nil
		}
		return self.jsContext.evaluateScript(text, withSourceURL: fileURL)
	}

}

