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

	public func call(args: [Any]) -> Any? {
		return self.action?.call(withArguments: args)
	}
}

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
	private var defaultsNameSpace: String

	/// Create an instance by given parameters.
	///
	/// - Parameters:
	///   - pluginFolderURL: Where are the JavaScript plug-ins located at.
	///   - defaultsNameSpace: A name space for setting user defaults.
	public init(pluginFolderURL: URL, defaultsNameSpace: String = "plug-ins") {
		self.pluginFolderURL = pluginFolderURL
		self.defaultsNameSpace = defaultsNameSpace
		self.buildJavaScriptAPIs()
	}

	fileprivate func buildJavaScriptAPIs() {

		// MARK: log
		let logFunction: @convention (block) (String?) -> Void = { log in
			if let log = log {
				print(log)
			}
		}
		self.jsContext.setObject(unsafeBitCast(logFunction, to: AnyObject.self), forKeyedSubscript: "log" as NSString)

		// MARK: openURL
		let openURL: @convention (block) (String?) -> Void = { urlString in
			guard let urlString = urlString else {
				return
			}
			guard let url = URL(string: urlString) else {
				return
			}
#if os(iOS)
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
#if os(OSX)
			NSWorkspace.shared.open(url)
#endif
		}
		self.jsContext.setObject(unsafeBitCast(openURL, to: AnyObject.self), forKeyedSubscript: "openURL" as NSString)

		// MARK: registerAction
		let registerPlugin: @convention (block) (JSValue!) -> Bool = { plugin in
			guard let plugin = plugin else {
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
			let enabled = self.checkIfPluginEnabledInUserDefaults(pluginID: pluginID)
			let pluginItem = ZBPlugin(ID: pluginID, title: title, action: action, enabled: enabled)
			self.plugins.append(pluginItem)
			return true
		}
		self.jsContext.setObject(unsafeBitCast(registerPlugin, to: AnyObject.self), forKeyedSubscript: "registerPlugin" as NSString)
	}

	func checkIfPluginEnabledInUserDefaults(pluginID: String) -> Bool {
		let settingMap = UserDefaults.standard.dictionary(forKey: defaultsNameSpace) as? [String: Bool] ?? [String: Bool]()
		return settingMap[pluginID] ?? true
	}

	/// Enable or disable a plugin.
	///
	/// - Parameters:
	///   - plugin: The plugin.
	///   - enabled: Enabled or not.
	public func toggle(plugin: ZBPlugin, enabled: Bool) {
		plugin.enabled = enabled
		var settingMap = UserDefaults.standard.dictionary(forKey: defaultsNameSpace) as? [String: Bool] ?? [String: Bool]()
		settingMap[plugin.title] = enabled
		UserDefaults.standard.set(settingMap, forKey: self.defaultsNameSpace)
	}

	/// Remove all plug-ins.
	public func reset() {
		plugins.removeAll()
	}

	/// Load all plug-ins from the given folder path.
	public func loadAllPlugins() {
		self.reset()
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

