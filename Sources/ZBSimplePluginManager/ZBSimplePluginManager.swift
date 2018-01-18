#if os(iOS)
import UIKit
#endif

#if os(OSX)
import AppKit
#endif

import JavaScriptCore

/// A plug-in.
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

enum ZBSimplePluginManagerError: Error {
	case overrideRegisterPluginAPI

	var localizedDescription: String {
		switch self {
		case .overrideRegisterPluginAPI:
			return NSLocalizedString("You cannot replace the \"registerPlugin\" function", comment: "error message")
		}
	}
}

/// ZBSimplePluginManager helps to load and manage JavaScript plug-ins.
public class ZBSimplePluginManager {
	/// All of the loaded plug-ins.
	public private(set) var plugins = [ZBPlugin]()
	/// A filtered list of enabled plug-ins.
	public var enabledPlugins: [ZBPlugin] {
		return self.plugins.filter { plugin in
			plugin.enabled
		}
	}

	fileprivate var jsContext: JSContext = JSContext()
	private var pluginFolderURL: URL
	private var defaultsNamespace: String

	/// A public property that helps to store values.
	public var valueStorage:[String: Any] = [String: Any]()

	/// Create an instance by given parameters.
	///
	/// - Parameters:
	///   - pluginFolderURL: Where are the JavaScript plug-ins located at.
	///   - defaultsNameSpace: A name space for setting user defaults.
	public init(pluginFolderURL: URL, defaultsNameSpace: String = "plug-ins") {
		self.pluginFolderURL = pluginFolderURL
		self.defaultsNamespace = defaultsNameSpace
		jsContext.name = "ZBSimplePluginManager"
		self.buildRegisterationAPI()
		self.buildJavaScriptAPIs()
	}

	/// Add new JavsScript function to the manager.
	///
	/// - Parameters:
	///   - functionName: Name of the function.
	///   - block: Implementation of the function.
	///   - input: Input value of the function.
	/// - Throws: Errors that cuase you cannot add new functions.
	public func addJavaScriptAPI(functionName: String, block: @escaping (_ input: Any?) -> (Any?)) throws {
		if functionName == "registerPlugin" {
			throw ZBSimplePluginManagerError.overrideRegisterPluginAPI
		}
		let objcBlock: @convention (block) (Any?) -> (Any?) = { input in
			return block(input)
		}
		self.jsContext.setObject(unsafeBitCast(objcBlock, to: AnyObject.self), forKeyedSubscript: functionName as NSString)
	}

	/// Add new JavsScript function to the manager.
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

	fileprivate func buildRegisterationAPI() {

		func checkIfPluginEnabledInUserDefaults(pluginID: String) -> Bool {
			let settingMap = UserDefaults.standard.dictionary(forKey: defaultsNamespace) as? [String: Bool] ?? [String: Bool]()
			return settingMap[pluginID] ?? true
		}

		let registerPlugin: @convention (block) (JSValue?) -> Bool = { pluginJSObject in
			guard let plugin = pluginJSObject else {
				return false
			}
			guard let pluginID = plugin.forProperty("id").toString() else {
				return false
			}
			let exitingPluginIDs = self.plugins.map {
				$0.ID
			}
			if exitingPluginIDs.contains(pluginID) {
				return false
			}
			guard let title = plugin.forProperty("title").toString() else {
				return false
			}
			let action = plugin.forProperty("action")
			let enabled = checkIfPluginEnabledInUserDefaults(pluginID: pluginID)
			let pluginItem = ZBPlugin(ID: pluginID, title: title, action: action, enabled: enabled)
			self.plugins.append(pluginItem)
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
				UIApplication.shared.open(url, options: [:], completionHandler:nil)
			#endif
			#if os(OSX)
				NSWorkspace.shared.open(url)
			#endif
			return nil
		}

		try? self.addJavaScriptAPI(functionName:"set") { key, value in
			guard let key = key as? String else {
				return nil
			}
			self.valueStorage[key] = value
			return nil
		}

		try? self.addJavaScriptAPI(functionName:"get") { key in
			guard let key = key as? String else {
				return nil
			}
			return self.valueStorage[key]
		}
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

	/// Remove all plug-ins.
	public func resetPlugins() {
		plugins.removeAll()
	}

	/// Load all plug-ins from the given folder path.
	public func loadAllPlugins() {
		self.resetPlugins()
		let pluginFolder = self.pluginFolderURL.path
		for path in FileManager.default.enumerator(atPath: pluginFolder)! {
			let fullpath = (pluginFolder as NSString).appendingPathComponent(path as! String)
			_ = self.loadJavaScript(fileURL: URL(fileURLWithPath: fullpath))
		}
	}

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

