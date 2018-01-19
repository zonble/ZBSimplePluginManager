import XCTest
import JavaScriptCore
@testable import ZBSimplePluginManager

class ZBSimplePluginManagerTests: XCTestCase {

	func createManager() -> ZBSimplePluginManager {
		let bundle = Bundle(for: ZBSimplePluginManagerTests.self)
		let resourceURL = URL(fileURLWithPath: bundle.resourcePath!)
		let pluginFolder = resourceURL.appendingPathComponent("PluginScripts")
		let manager = ZBSimplePluginManager(pluginFolderURL: pluginFolder, defaultsNamespace: "test")
		return manager
	}

	func testLoadPlugin() {
		let manager = createManager()
		XCTAssertTrue(manager.plugins.count == 0)
		manager.loadAllPlugins()
		XCTAssertTrue(manager.plugins.count > 0)
	}

	func testResetPlugin() {
		let manager = createManager()
		manager.loadAllPlugins()
		XCTAssertTrue(manager.plugins.count > 0)
		manager.resetPlugins()
		XCTAssertTrue(manager.plugins.count == 0)
	}

	func testRegisterPlugin() {
		let script =
		"""
var printPlugin = {
  id: 'plugin.print',
  title: 'Print',
  action: function (keyword) {
	print(keyword)
  }
}
registerPlugin(printPlugin)
"""
		let manager = createManager()
		_ = manager.loadJavaScript(string: script)
		XCTAssertTrue(manager.plugins.count == 1)
		let plugin = manager.plugins[0]
		XCTAssertTrue(plugin.ID == "plugin.print")
		XCTAssertTrue(plugin.title == "Print")
		let result = plugin.call(args: ["Hi"])
		XCTAssertTrue(result as? String == nil)
	}

	func testArray() {
		let script =
		"""
var arrayPlugin = {
  id: 'plugin.Array',
  title: 'Array',
  action: function (key) {
	return [1, 2]
  }
}
registerPlugin(arrayPlugin)
"""
		let manager = createManager()
		_ = manager.loadJavaScript(string: script)
		XCTAssertTrue(manager.plugins.count == 1)
		let plugin = manager.plugins[0]
		let result = (plugin.call(args: []) as? JSValue)?.toArray()
		XCTAssertTrue(result?.count == 2)
		XCTAssertTrue(result?[0] as? Int == 1)
		XCTAssertTrue(result?[1] as? Int == 2)
	}

	func testSet() {
		let script =
		"""
var setPlugin = {
  id: 'plugin.set',
  title: 'Set',
  action: function (keyword) {
	set("key", "value")
  }
}
registerPlugin(setPlugin)
"""
		let manager = createManager()
		_ = manager.loadJavaScript(string: script)
		XCTAssertTrue(manager.plugins.count == 1)
		let plugin = manager.plugins[0]
		_ = plugin.call(args: [])
		XCTAssertTrue(manager.valueStorage["key"] as? String == "value")
	}

	func testGet() {
		let script =
		"""
var getPlugin = {
  id: 'plugin.get',
  title: 'Get',
  action: function (key) {
	return get(key)
  }
}
registerPlugin(getPlugin)
"""
		let manager = createManager()
		_ = manager.loadJavaScript(string: script)
		XCTAssertTrue(manager.plugins.count == 1)
		let key = "key"
		let value = "value"
		manager.valueStorage[key] = value
		let plugin = manager.plugins[0]
		let result = (plugin.call(args: [key]) as? JSValue)?.toString()
		XCTAssertTrue(result == value)
	}

	func testDisablePugin() {
		let manager = createManager()
		manager.loadAllPlugins()
		manager.resetSettings()
		let plugin = manager.plugins[0]
		manager.toggle(plugin: plugin, enabled: false)
		XCTAssertTrue(manager.plugins.count == manager.enabledPlugins.count + 1)
		manager.toggle(plugin: plugin, enabled: true)
		XCTAssertTrue(manager.plugins.count == manager.enabledPlugins.count)
	}

	static var allTests = [
        ("testLoadPlugin", testLoadPlugin),
		("testResetPlugin", testResetPlugin),
		("testRegisterPlugin", testRegisterPlugin),
		("testArray", testArray),
		("testSet", testSet),
		("testGet", testGet),
		("testDisablePugin", testDisablePugin),
	]
}
